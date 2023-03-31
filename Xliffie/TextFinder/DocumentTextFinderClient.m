//
//  DocumentTextFinderClient.m
//  Xliffie
//
//  Created by b123400 on 2023/03/24.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "DocumentTextFinderClient.h"
#import "DocumentTextFinderClientEntry.h"

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
    return NO;
}

- (BOOL)allowsMultipleSelection {
    return NO;
}

- (void)setDocument:(Document *)document {
    _document = document;
    [self reload];
}

- (void)reload {
    int currentCharacterIndex = 0;
    NSMutableArray<DocumentTextFinderClientEntry *> *entries = [[NSMutableArray alloc] init];
    for (TranslationPair *pair in [self.document allTranslationPairs]) {
        DocumentTextFinderClientEntry *sourceEntry = [[DocumentTextFinderClientEntry alloc] init];
        sourceEntry.type = DocumentTextFinderClientEntryTypeSource;
        sourceEntry.pair = pair;
        sourceEntry.range = NSMakeRange(currentCharacterIndex, pair.source.length);
        currentCharacterIndex += pair.source.length;
        [entries addObject:sourceEntry];

        if (pair.target.length) {
            DocumentTextFinderClientEntry *targetEntry = [[DocumentTextFinderClientEntry alloc] init];
            targetEntry.type = DocumentTextFinderClientEntryTypeTarget;
            targetEntry.pair = pair;
            targetEntry.range = NSMakeRange(currentCharacterIndex, pair.target.length);
            currentCharacterIndex += pair.target.length;
            [entries addObject:targetEntry];
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
        NSInteger index = [self.outlineView rowForItem:entry.pair];
        if (index != -1) {
            [self.outlineView scrollRowToVisible:index];
        }
    }
}

- (NSView *)contentViewAtIndex:(NSUInteger)characterIndex effectiveCharacterRange:(NSRangePointer)outRange {
    for (DocumentTextFinderClientEntry *entry in self.entries) {
        if (!NSLocationInRange(characterIndex, entry.range)) continue;
        NSInteger index = [self.outlineView rowForItem:entry.pair];
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
    NSInteger row = [self.outlineView rowForItem:entry.pair];
    NSRect cellFrame = [self.outlineView frameOfCellAtColumn:entry.type == DocumentTextFinderClientEntryTypeSource ? 0 : 1 row:row];
    NSCell *cell = [column dataCellForRow:row];
    NSRange range = NSMakeRange(inRange.location - entry.range.location, inRange.length);

    if ([cell isKindOfClass:[NSTextFieldCell class]]) {
        NSRect textBounds = [cell titleRectForBounds:cellFrame];
        [cell setStringValue:entry.string];
        NSTextContainer* textContainer = [[NSTextContainer alloc] init];
        NSLayoutManager* layoutManager = [[NSLayoutManager alloc] init];
        NSTextStorage* textStorage = [[NSTextStorage alloc] init];
        [layoutManager addTextContainer:textContainer];
        [textStorage addLayoutManager:layoutManager];
        textContainer.lineFragmentPadding = 2;
        layoutManager.typesetterBehavior = NSTypesetterBehavior_10_2_WithCompatibility;

        textContainer.containerSize = textBounds.size;
        [textStorage beginEditing];
        textStorage.attributedString = cell.attributedStringValue;
        [textStorage endEditing];

        NSUInteger count;
        NSRectArray rects = [layoutManager rectArrayForCharacterRange:range
                                         withinSelectedCharacterRange:range
                                                      inTextContainer:textContainer
                                                            rectCount:&count];
        NSMutableArray<NSValue *> *values = [NSMutableArray array];
        for (NSUInteger i = 0; i < count; i++)
        {
            NSRect rect = NSOffsetRect(rects[i], textBounds.origin.x, textBounds.origin.y);
            [values addObject:[NSValue valueWithRect:rect]];
        }
        return values;
    } else {
        return nil;
    }
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
        [cell drawWithFrame:cellRect inView:self.outlineView];
    }
    self.outlineView.usesAlternatingRowBackgroundColors = YES;
}

@end
