//
//  DocumentWindowSplitView.m
//  Xliffie
//
//  Created by b123400 on 16/2/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "DocumentWindowSplitView.h"

@implementation DocumentWindowSplitView

-(void)collapseRightView {
    NSView *right = [[self subviews] objectAtIndex:1];
    NSView *left  = [[self subviews] objectAtIndex:0];
    NSRect leftFrame = [left frame];
    NSRect overallFrame = [self frame];
    [right setHidden:YES];
    [left setFrameSize:NSMakeSize(overallFrame.size.width,leftFrame.size.height)];
    [self display];
}

-(void)uncollapseRightView {
    NSView *left  = [[self subviews] objectAtIndex:0];
    NSView *right = [[self subviews] objectAtIndex:1];
    [right setHidden:NO];
    CGFloat dividerThickness = [self dividerThickness];
    // get the different frames
    NSRect leftFrame = [left frame];
    NSRect rightFrame = [right frame];
    // Adjust left frame size
    rightFrame.size.width = MAX(rightFrame.size.width, 200);
    rightFrame.size.width = MIN(self.window.frame.size.width * 0.5, 200);

    leftFrame.size.width = (leftFrame.size.width-rightFrame.size.width-dividerThickness);
    rightFrame.origin.x = leftFrame.size.width + dividerThickness;
    
    [left setFrameSize:leftFrame.size];
    [right setFrame:rightFrame];
    [self display];
}

@end
