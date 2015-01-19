//
//  DocumentWindow.m
//  Xliffie
//
//  Created by b123400 on 19/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "DocumentWindow.h"

@implementation DocumentWindow

- (void)performFindPanelAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(documentWindowSearchKeyPressed:)]) {
        [self.delegate documentWindowSearchKeyPressed:self];
    }
}

- (void)showInfo:(id)sender {
    if ([self.delegate respondsToSelector:@selector(documentWindowShowInfoPressed:)]) {
        [self.delegate documentWindowShowInfoPressed:self];
    }
}

@end
