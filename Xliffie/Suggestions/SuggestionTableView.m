//
//  SuggestionTableView.m
//  Xliffie
//
//  Created by b123400 on 2023/08/08.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "SuggestionTableView.h"

@implementation SuggestionTableView {
    NSTrackingRectTag trackingTag;
}


- (void)awakeFromNib
{
    [[self window] setAcceptsMouseMovedEvents:YES];
    trackingTag = [self addTrackingRect:[self frame] owner:self userData:nil assumeInside:NO];
}

- (void)dealloc
{
    [self removeTrackingRect:trackingTag];
}

- (void)mouseMoved:(NSEvent*)theEvent
{
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger row = [self rowAtPoint:point];
    if (![self.delegate tableView:self shouldSelectRow:row]) return;
    if (row == -1) {
        [self selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
        return;
    }
    if (row != [self selectedRow]) {
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
}

- (void)mouseExited:(NSEvent *)event {
    [self selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
}

@end
