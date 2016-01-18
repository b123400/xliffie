//
//  DocumentWindowController.h
//  Xliffie
//
//  Created by b123400 on 18/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DocumentViewController.h"
#import "DocumentWindow.h"

@interface DocumentWindowController : NSWindowController <DocumentViewControllerDelegate, DocumentWindowDelegate, NSSplitViewDelegate, NSWindowRestoration>

- (void)toggleNotes;

- (NSString*)baseFolderPath;
- (void)addDocument:(Document*)newDocument;

- (void)openDocumentDrawer;

@end
