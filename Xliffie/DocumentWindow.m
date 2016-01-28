//
//  DocumentWindow.m
//  Xliffie
//
//  Created by b123400 on 19/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "DocumentWindow.h"
#import "DocumentWindowController.h"

@implementation DocumentWindow

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    self = [super initWithContentRect:contentRect
                            styleMask:aStyle
                              backing:bufferingType
                                defer:flag];
    self.oneShot = YES;
    self.releasedWhenClosed = YES;
    return self;
}

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

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [self.windowController encodeRestorableStateWithCoder:coder];
    [super encodeRestorableStateWithCoder:coder];
}

- (Class<NSWindowRestoration>)restorationClass {
    return [DocumentWindowController class];
}

- (void)close {
    self.windowController = nil;
    [super close];
}

@end
