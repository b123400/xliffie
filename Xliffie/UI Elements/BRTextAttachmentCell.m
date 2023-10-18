//
//  MyTextAttachmentCell.m
//  Xliffie
//
//  Created by b123400 on 2023/10/17.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "BRTextAttachmentCell.h"

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
    [path appendBezierPathWithRoundedRect:NSMakeRect(cellFrame.origin.x, cellFrame.origin.y + 5, cellFrame.size.width, cellFrame.size.height - 1) xRadius:5 yRadius:5];
    [self.backgroundColor setFill];
    [path fill];
    
    [self.text drawAtPoint:NSMakePoint(cellFrame.origin.x + 5, cellFrame.origin.y + 6) withAttributes:@{
        NSForegroundColorAttributeName: self.textColor
    }];
}

+ (NSString *)stringForAttributedString:(NSAttributedString *)input {
    // Turn tokens back into normal string
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

@end
