//
//  RoundedCornersView.m
//  Xliffie
//
//  Created by b123400 on 2022/12/06.
//  Copyright © 2022 b123400. All rights reserved.
//

#import "RoundedCornersView.h"

@implementation RoundedCornersView

- (void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:16 yRadius:16];
    [[NSColor windowBackgroundColor] setFill];
    [borderPath fill];
}

@end
