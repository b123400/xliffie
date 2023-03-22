//
//  TranslationTargetCell.m
//  Xliffie
//
//  Created by b123400 on 9/3/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "TranslationTargetCell.h"

@implementation TranslationTargetCell


- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj {
    NSText *t = [super setUpFieldEditorAttributes:textObj];
    t.backgroundColor = [NSColor textBackgroundColor];
    t.textColor = [NSColor textColor];
    return t;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [super drawWithFrame:cellFrame inView:controlView];
    if (self.dotColor) {
        NSGraphicsContext *gc = [NSGraphicsContext currentContext];
        [gc saveGraphicsState];
        
        [self.dotColor setFill];
        CGFloat width = 7;
        NSRect circleRect = NSMakeRect(NSMaxX(cellFrame) - width,
                                       NSMinY(cellFrame) + (NSHeight(cellFrame) - width)/2,
                                       width,
                                       width);
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithOvalInRect:circleRect];
        [path fill];
        
        [gc restoreGraphicsState];
    }
}

- (void)setDotColor:(NSColor *)dotColor {
    if (_dotColor != dotColor) {
        _dotColor = dotColor;
        [self.controlView setNeedsDisplay:YES];
    }
}

@end
