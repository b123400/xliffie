//
//  BRArrowSegmentedCell.m
//  Xliffie
//
//  Created by b123400 on 24/1/2016.
//  Copyright © 2016 b123400. All rights reserved.
//

#import "BRArrowSegmentedCell.h"

@interface BRArrowSegmentedCell ()
@property (nonatomic, assign) BOOL dontDrawInterior;
@end

@implementation BRArrowSegmentedCell

- (instancetype)init {
    self = [super init];
    [self initCommon];
    return self;
}

- (instancetype)initImageCell:(NSImage *)image {
    self = [super initImageCell:image];
    [self initCommon];
    return self;
}

- (instancetype)initTextCell:(NSString *)aString {
    self = [super initTextCell:aString];
    [self initCommon];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self initCommon];
    return self;
}

- (void)initCommon {
    self.arrowSize = NSMakeSize(6, 15);
}

#pragma mark Drawing

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if (self.dontDrawInterior) return;
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(NSView *)controlView
{
    if (segment != self.segmentCount -1) { // except last segment
        
        // Remove the separator by drawing the background on the separator
        
        [NSGraphicsContext saveGraphicsState];
        CGFloat separatorWidth = 2;
        NSRect shiftedAbsoluteFrame = NSMakeRect(separatorWidth, 0,
                                                 controlView.bounds.size.width,
                                                 controlView.bounds.size.height);
        
        NSRect separatorRect = NSMakeRect(frame.origin.x + frame.size.width, 0,
                                          separatorWidth, controlView.bounds.size.height);
        
        // Remove the separator
        CGContextClearRect([[NSGraphicsContext currentContext] graphicsPort], NSRectToCGRect(separatorRect));
        
        // Clip the separator rect
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:separatorRect];
        [path setClip];
        
        // Draw background with a shifted rect.
        self.dontDrawInterior = YES;
        [self drawWithFrame:shiftedAbsoluteFrame inView:controlView];
        self.dontDrawInterior = NO;
        
        [NSGraphicsContext restoreGraphicsState];
        
        // Draw arrow
        CGFloat separatorCenter = separatorRect.origin.x + separatorWidth/2.0f;
        CGFloat yShift = 1;
        NSBezierPath *arrowPath = [NSBezierPath bezierPath];
        [arrowPath moveToPoint:NSMakePoint(separatorCenter - self.arrowSize.width / 2,
                                           (frame.origin.y + frame.size.height)/2 - (self.arrowSize.height/2) + yShift)];
        [arrowPath lineToPoint:NSMakePoint(separatorCenter + self.arrowSize.width / 2,
                                           (frame.origin.y + frame.size.height)/2 + yShift)];
        [arrowPath lineToPoint:NSMakePoint(separatorCenter - self.arrowSize.width / 2,
                                           (frame.origin.y + frame.size.height)/2 + (self.arrowSize.height/2)+ + yShift)];
        [arrowPath setLineWidth:1.0f];
        [[NSColor grayColor] setStroke];
        [arrowPath stroke];
    }
    [super drawSegment:segment inFrame:frame withView:controlView];
}

@end
