//
//  MyTextAttachmentCell.m
//  Xliffie
//
//  Created by b123400 on 2023/10/17.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "BRTextAttachmentCell.h"
#import "BRTextAttachmentFindResult.h"

@implementation BRTextAttachmentCell

- (instancetype)initTextCell:(NSString *)string {
    if (self = [super initTextCell:string]) {
        self.text = string;
        self.backgroundColor = [NSColor systemBlueColor];
        self.textColor = [NSColor whiteColor];
    }
    return self;
}

- (NSSize)cellSize {
    NSSize size = [self.text boundingRectWithSize:NSMakeSize(10000, 10000) options:0 attributes:nil].size;
    return NSMakeSize(size.width + 10, size.height + 3);
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRoundedRect:NSMakeRect(cellFrame.origin.x, cellFrame.origin.y + 3, cellFrame.size.width, cellFrame.size.height) xRadius:5 yRadius:5];
    if (self.strokeInsteadOfFill) {
        [[NSColor controlBackgroundColor] setFill];
        [path fill];
        [self.backgroundColor setStroke];
        [path stroke];
    } else {
        [self.backgroundColor setFill];
        [path fill];
    }
    
    [self.text drawAtPoint:NSMakePoint(cellFrame.origin.x + 5, cellFrame.origin.y + 4) withAttributes:@{
        NSForegroundColorAttributeName: self.textColor
    }];
}

- (NSArray<NSValue*> *)rectsOfTextRange:(NSRange)range withCellFrame:(NSRect)cellFrame {
    NSRect textBounds = NSOffsetRect(cellFrame, 0, 4);
    NSTextContainer* textContainer = [[NSTextContainer alloc] init];
    NSLayoutManager* layoutManager = [[NSLayoutManager alloc] init];
    NSTextStorage* textStorage = [[NSTextStorage alloc] init];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    textContainer.lineFragmentPadding = 2;
    layoutManager.typesetterBehavior = NSTypesetterBehavior_10_2_WithCompatibility;
    textContainer.containerSize = textBounds.size;
    [textStorage beginEditing];
    textStorage.attributedString = self.attributedStringValue;
    textStorage.font = self.font;
    [textStorage endEditing];
    NSUInteger count;
    NSRectArray rects = [layoutManager rectArrayForCharacterRange:range
                                     withinSelectedCharacterRange:range
                                                  inTextContainer:textContainer
                                                        rectCount:&count];
    NSMutableArray<NSValue*> *result = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        [result addObject:[NSValue valueWithRect:rects[i]]];
    }
    return result;
}

/// Turn tokens back into normal string
+ (NSString *)stringForAttributedString:(NSAttributedString *)input {
    NSMutableAttributedString *m = [input mutableCopy];
    [input enumerateAttribute:NSAttachmentAttributeName
                               inRange:NSMakeRange(0, m.length)
                               options:NSAttributedStringEnumerationReverse
                            usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        if ([value isKindOfClass:[NSTextAttachment class]] && [[(NSTextAttachment*)value attachmentCell] isKindOfClass:[BRTextAttachmentCell class]]) {
            BRTextAttachmentCell *cell = (BRTextAttachmentCell*)[(NSTextAttachment*)value attachmentCell];
            [m replaceCharactersInRange:range withString:cell.text];
        }
    }];
    return [[m string] stringByReplacingOccurrencesOfString:@"\U0000fffc" withString:@""];
}

/// Given an attributedString, and the a range of its plaintext representation, returns an array of find result with range relative to the attributed string, for NSTextFinder highlight
+ (NSArray<BRTextAttachmentFindResult*> *)findTextRangesWithPlainTextRange:(NSRange)inputRange fromAttributedString:(NSAttributedString *)attrString {
    __block NSUInteger delta = 0;
    NSString *plainText = [BRTextAttachmentCell stringForAttributedString:attrString];
    NSMutableArray<BRTextAttachmentFindResult*> *results = [NSMutableArray array];
    __block NSUInteger nonAttributedStartAt = 0;
    [attrString enumerateAttribute:NSAttachmentAttributeName
                           inRange:NSMakeRange(0, attrString.length)
                           options:0
                        usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        if ([value isKindOfClass:[NSTextAttachment class]] && [[(NSTextAttachment*)value attachmentCell] isKindOfClass:[BRTextAttachmentCell class]]) {
            BRTextAttachmentCell *cell = (BRTextAttachmentCell*)[(NSTextAttachment*)value attachmentCell];
            NSRange plainTextRange = NSMakeRange(range.location + delta, cell.text.length);
            
            NSRange nonAttributedPlainTextRange = NSMakeRange(nonAttributedStartAt, plainTextRange.location - nonAttributedStartAt);
            nonAttributedStartAt = NSMaxRange(plainTextRange);

            NSRange intersection = NSIntersectionRange(inputRange, plainTextRange);
            if (intersection.length) {
                BRTextAttachmentFindResult *result = [[BRTextAttachmentFindResult alloc] init];
                result.cell = cell;
                result.rangeOfAttachment = range;
                result.range = NSMakeRange(intersection.location - plainTextRange.location, intersection.length);
                [results addObject:result];
            }
            
            intersection = NSIntersectionRange(inputRange, nonAttributedPlainTextRange);
            if (intersection.length) {
                BRTextAttachmentFindResult *result = [[BRTextAttachmentFindResult alloc] init];
                result.range = NSMakeRange(intersection.location - delta, intersection.length);
                result.sourceText = attrString;
                [results addObject:result];
            }

            delta += cell.text.length - 1;
        }
    }];
    NSRange lastNonAttributedRange = NSMakeRange(nonAttributedStartAt, plainText.length - nonAttributedStartAt);
    NSRange lastIntersection = NSIntersectionRange(lastNonAttributedRange, inputRange);
    if (lastIntersection.length) {
        BRTextAttachmentFindResult *result = [[BRTextAttachmentFindResult alloc] init];
        result.range = NSMakeRange(lastIntersection.location - delta, lastIntersection.length);
        result.sourceText = attrString;
        [results addObject:result];
    }
    return results;
}

@end
