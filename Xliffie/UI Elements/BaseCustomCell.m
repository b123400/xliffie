//
//  BaseCustomCell.m
//  Xliffie
//
//  Created by b123400 on 2023/03/30.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "BaseCustomCell.h"

@implementation BaseCustomCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if (controlView.isDrawingFindIndicator) {
        // When it's in searching mode, the background is always yellow
        // so we need to force it to black for all occasion, even if it's dark mode.
        NSColor *c = self.textColor;
        self.textColor = [NSColor blackColor];
        [super drawWithFrame:cellFrame inView:controlView];
        self.textColor = c;
    } else {
        [super drawWithFrame:cellFrame inView:controlView];
    }
}

@end
