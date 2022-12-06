//
//  XMLOutlineView.h
//  Xliffie
//
//  Created by b123400 on 8/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol XMLOutlineViewDelegate <NSObject>

- (void)xmlOutlineView:(id)sender didEndEditingRow:(NSInteger)row proposedString:(NSString*)proposed callback:(void (^)(BOOL shouldEnd))callback;
- (void)xmlOutlineView:(id)sender didStartEditingColumn:(NSInteger)column row:(NSInteger)row event:(NSEvent*)event;

@end

@interface XMLOutlineView : NSOutlineView

@property (weak) id <XMLOutlineViewDelegate> xmlOutlineDelegate;

@end
