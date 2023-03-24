//
//  BRProgressButton.m
//  Xliffie
//
//  Created by b123400 on 2023/03/22.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "BRProgressButton.h"

@interface BRProgressButton ()

@property (nonatomic, strong) NSMutableArray<NSNumber*> *progresses;
@property (nonatomic, strong) NSMutableArray<NSColor*> *colours;


@end

@implementation BRProgressButton

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        self.progresses = [NSMutableArray array];
        self.colours = [NSMutableArray array];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSGraphicsContext *gc = [NSGraphicsContext currentContext];
    NSPoint center = NSMakePoint(self.bounds.size.width/2, self.bounds.size.height/2);
    
    CGFloat radius = (MIN(self.bounds.size.width, self.bounds.size.height) - 2) / 2;
    [gc saveGraphicsState];
    double startAngle = -90;
    for (int i = 0; i < self.progresses.count; i++) {
        NSNumber *progress = self.progresses[i];
        NSColor *colour = self.colours[i];
        double endAngle = startAngle + [progress doubleValue] * 360;
        
        [colour setFill];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithArcWithCenter:center
                                         radius:radius
                                     startAngle:startAngle
                                       endAngle:endAngle
                                      clockwise:NO];
        [path appendBezierPathWithArcWithCenter:center
                                         radius:radius - 5
                                     startAngle:endAngle
                                       endAngle:startAngle
                                      clockwise:YES];
        [path fill];
        startAngle = endAngle;
    }
    [gc restoreGraphicsState];
}

- (void)addSegmentWithProgress:(double)progress colour:(NSColor *)colour {
    [self.progresses addObject:@(progress)];
    [self.colours addObject:colour];
    [self setNeedsDisplay];
}

- (void)resetSegments {
    [self.progresses removeAllObjects];
    [self.colours removeAllObjects];
}

@end
