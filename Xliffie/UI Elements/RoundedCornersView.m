//
//  RoundedCornersView.m
//  Xliffie
//
//  Created by b123400 on 2022/12/06.
//  Copyright © 2022 b123400. All rights reserved.
//

#import "RoundedCornersView.h"

@implementation RoundedCornersView


- (CGFloat)radius {
    return _radius ?: 16;
}

- (NSColor *)backgroundColor {
    return _backgroundColor ?: [NSColor windowBackgroundColor];
}

- (void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:self.radius yRadius:self.radius];
    [self.backgroundColor setFill];
    [borderPath fill];
}

@end
