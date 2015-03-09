//
//  DocumentListDrawer.h
//  Xliffie
//
//  Created by b123400 on 8/3/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol DocumentListDrawerDelegate <NSDrawerDelegate>

- (NSArray*)documentsForDrawer:(id)drawer;
- (void)documentDrawer:(id)sender didSelectedDocumentAtIndex:(NSUInteger)index;

@end

@interface DocumentListDrawer : NSDrawer

@property (atomic, weak) id<DocumentListDrawerDelegate> delegate;

- (void)reloadData;
- (void)selectDocumentAtIndex:(NSUInteger)index;

@end
