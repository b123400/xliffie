//
//  DocumentTextFinderClient.m
//  Xliffie
//
//  Created by b123400 on 2023/03/24.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "DocumentTextFinderClient.h"
#import "DocumentTextFinderClientEntry.h"
#import "BRTextAttachmentCell.h"
#import "BRTextAttachmentFindResult.h"

@interface DocumentTextFinderClient ()

@property (nonatomic, strong) NSArray<DocumentTextFinderClientEntry*> *entries;

@end

@implementation DocumentTextFinderClient

- (instancetype)initWithDocument:(Document*)document {
    if (self = [super init]) {
        self.document = document;
    }
    return self;
}

- (BOOL)isSelectable {
    return YES;
}

- (NSArray<NSValue *> *)selectedRanges {
    NSInteger row = [self.outlineView selectedRow];
    if (row < 0) return @[];
    id item = [self.outlineView itemAtRow:row];
    NSMutableArray *result = [NSMutableArray array];
    for (DocumentTextFinderClientEntry *entry in self.entries) {
        if (entry.pair == item || entry.pairGroup == item) {
            [result addObject:[NSValue valueWithRange:entry.range]];
        }
    }
    return result;
}

- (NSRange)firstSelectedRange {
    NSInteger row = [self.outlineView selectedRow];
    if (row > 0) {
        id item = [self.outlineView itemAtRow:row];
        for (DocumentTextFinderClientEntry *entry in self.entries) {
            if (entry.pair == item || entry.pairGroup == item) {
                return entry.range;
            }
        }
    }
    return NSMakeRange(0, 0);
}

- (BOOL)allowsMultipleSelection {
    return NO;
}

- (void)setSelectedRanges:(NSArray<NSValue *> *)selectedRanges {
    if (![selectedRanges count]) {
        [self.outlineView deselectAll:self];
        return;
    }
    NSRange selectedRange = [[selectedRanges firstObject] rangeValue];
    for (DocumentTextFinderClientEntry *entry in self.entries) {
        NSRange intersection = NSIntersectionRange(selectedRange, entry.range);
        if (intersection.length > 0) {
            [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.outlineView rowForItem:entry.pairGroup ?: entry.pair]] byExtendingSelection:NO];
            break;
        }
    }
}

- (void)setDocument:(Document *)document {
    _document = document;
    [self reload];
}

- (void)reload {
    int currentCharacterIndex = 0;
    NSMutableArray<DocumentTextFinderClientEntry *> *entries = [[NSMutableArray alloc] init];
    for (File *file in self.document.files) {
        for (id pairOrGroup in [file groupedTranslations]) {
            TranslationPair *pair = nil;
            TranslationPairGroup *group = nil;
            if ([pairOrGroup isKindOfClass:[TranslationPair class]]) {
                pair = pairOrGroup;
            } else if ([pairOrGroup isKindOfClass:[TranslationPairGroup class]] && [pairOrGroup mainPair]) {
                group = pairOrGroup;
                pair = [group mainPair];
            }
            if (!pair) {
                // Groups without pair are not searched
                continue;
            }
            DocumentTextFinderClientEntry *sourceEntry = [[DocumentTextFinderClientEntry alloc] init];
            sourceEntry.type = DocumentTextFinderClientEntryTypeSource;
            sourceEntry.pair = pair;
            sourceEntry.pairGroup = group;
            NSString *actualString = [pair plainSourceForDisplayWithModifier];
            sourceEntry.range = NSMakeRange(currentCharacterIndex, actualString.length);
            currentCharacterIndex += actualString.length;
            [entries addObject:sourceEntry];

            if (pair.target.length) {
                DocumentTextFinderClientEntry *targetEntry = [[DocumentTextFinderClientEntry alloc] init];
                targetEntry.type = DocumentTextFinderClientEntryTypeTarget;
                targetEntry.pair = pair;
                targetEntry.pairGroup = group;
                targetEntry.range = NSMakeRange(currentCharacterIndex, pair.target.length);
                currentCharacterIndex += pair.target.length;
                [entries addObject:targetEntry];
            }
        }
    }
    self.entries = entries;
}

- (NSUInteger)stringLength {
    NSRange lastRange = [self.entries.lastObject range];
    return lastRange.location + lastRange.length;
}

- (NSString *)stringAtIndex:(NSUInteger)characterIndex effectiveRange:(NSRangePointer)outRange endsWithSearchBoundary:(BOOL *)outFlag {
    for (DocumentTextFinderClientEntry *entry in self.entries) {
        if (!NSLocationInRange(characterIndex, entry.range)) continue;
        *outRange = entry.range;
        *outFlag = YES;
        return [entry string];
    }
    return nil;
}

- (void)scrollRangeToVisible:(NSRange)range {
    for (DocumentTextFinderClientEntry *entry in self.entries) {
        if (!NSLocationInRange(range.location, entry.range)) continue;
        NSInteger index = [self.outlineView rowForItem:entry.pairGroup ?: entry.pair];
        if (index != -1) {
            [self.outlineView scrollRowToVisible:index];
        }
    }
}

- (NSView *)contentViewAtIndex:(NSUInteger)characterIndex effectiveCharacterRange:(NSRangePointer)outRange {
    for (DocumentTextFinderClientEntry *entry in self.entries) {
        if (!NSLocationInRange(characterIndex, entry.range)) continue;
        NSInteger index = [self.outlineView rowForItem:entry.pairGroup ?: entry.pair];
        if (index != -1) {
            *outRange = entry.range;
            return self.outlineView;
        }
    }
    return nil;
}

- (NSArray<NSValue *> *)rectsForCharacterRange:(NSRange)inRange {
    DocumentTextFinderClientEntry *entry = nil;
    for (DocumentTextFinderClientEntry *e in self.entries) {
        if (NSLocationInRange(inRange.location, e.range)) {
            entry = e;
            break;
        }
    }
    NSTableColumn *column = entry.type == DocumentTextFinderClientEntryTypeSource
        ? [self.outlineView tableColumnWithIdentifier:@"source"]
        : [self.outlineView tableColumnWithIdentifier:@"target"];
    NSInteger row = [self.outlineView rowForItem:entry.pairGroup ?: entry.pair];
    NSRect cellFrame = [self.outlineView frameOfCellAtColumn:entry.type == DocumentTextFinderClientEntryTypeSource ? 0 : 1 row:row];
    NSCell *cell = [column dataCellForRow:row];
    NSRange range = NSMakeRange(inRange.location - entry.range.location, inRange.length);
    
    NSAttributedString *entryAttributedString = entry.attributedString;
    NSArray<BRTextAttachmentFindResult*> *findResults = [BRTextAttachmentCell findTextRangesWithPlainTextRange:range fromAttributedString:entryAttributedString];

    NSRect textBounds = [cell titleRectForBounds:cellFrame];
    NSTextContainer* textContainer = [[NSTextContainer alloc] init];
    NSLayoutManager* layoutManager = [[NSLayoutManager alloc] init];
    NSTextStorage* textStorage = [[NSTextStorage alloc] init];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    textContainer.lineFragmentPadding = 2;
    layoutManager.typesetterBehavior = NSTypesetterBehavior_10_2_WithCompatibility;
    textContainer.containerSize = textBounds.size;
    
    NSMutableArray<NSValue *> *outRects = [NSMutableArray array];

    for (BRTextAttachmentFindResult *findResult in findResults) {
        [textStorage beginEditing];
        textStorage.attributedString = entryAttributedString;
        textStorage.font = cell.font;
        [textStorage endEditing];
        if (findResult.cell) {
            NSUInteger count;
            NSRectArray rects = [layoutManager rectArrayForCharacterRange:findResult.rangeOfAttachment
                                             withinSelectedCharacterRange:findResult.rangeOfAttachment
                                                          inTextContainer:textContainer
                                                                rectCount:&count];
            if (count > 0) {
                NSRect rect = NSOffsetRect(rects[0], textBounds.origin.x, textBounds.origin.y);
                if (findResult.cell.text.length == findResult.range.length) {
                    [outRects addObject:[NSValue valueWithRect:rect]];
                } else {
                    NSArray *rectsInAttachment = [findResult.cell rectsOfTextRange:findResult.range withCellFrame:cellFrame];
                    for (NSValue *rectInAttachment in rectsInAttachment) {
                        [outRects addObject:[NSValue valueWithRect:NSOffsetRect(rectInAttachment.rectValue, rect.origin.x, rect.origin.y)]];
                    }
                }
            }
        } else {
            NSUInteger count;
            NSRectArray rects = [layoutManager rectArrayForCharacterRange:findResult.range
                                             withinSelectedCharacterRange:findResult.range
                                                          inTextContainer:textContainer
                                                                rectCount:&count];
            for (NSUInteger i = 0; i < count; i++)
            {
                NSRect rect = NSOffsetRect(rects[i], textBounds.origin.x, textBounds.origin.y);
                [outRects addObject:[NSValue valueWithRect:rect]];
            }
        }
    }
    return outRects;
}

- (void)drawCharactersInRange:(NSRange)range forContentView:(NSView *)view {
    self.outlineView.usesAlternatingRowBackgroundColors = NO;
    NSArray<NSValue *> *values = [self rectsForCharacterRange:range];
    for (NSValue *v in values) {
        NSRect rect = v.rectValue;
        NSInteger row = [self.outlineView rowAtPoint:rect.origin];
        NSInteger col = [self.outlineView columnAtPoint:rect.origin];
        NSCell *cell = [self.outlineView.tableColumns[col] dataCellForRow:row];
        NSRect cellRect = [self.outlineView frameOfCellAtColumn:col row:row];
        
        DocumentTextFinderClientEntry *entry = nil;
        for (DocumentTextFinderClientEntry *e in self.entries) {
            if (NSLocationInRange(range.location, e.range)) {
                entry = e;
                break;
            }
        }
        [cell setAttributedStringValue:entry.attributedString];

        [cell drawWithFrame:cellRect inView:self.outlineView];
    }
    self.outlineView.usesAlternatingRowBackgroundColors = YES;
}

@end
