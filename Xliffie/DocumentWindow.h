//
//  DocumentWindow.h
//  Xliffie
//
//  Created by b123400 on 19/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol DocumentWindowDelegate <NSWindowDelegate>

@optional
- (void)documentWindowSearchKeyPressed:(id)documentWindow;
- (void)documentWindowShowInfoPressed:(id)documentWindow;

@end

@interface DocumentWindow : NSWindow

@property (weak) id <DocumentWindowDelegate> delegate;

@end
