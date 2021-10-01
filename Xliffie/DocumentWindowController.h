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
#import "DocumentListViewController.h"

@interface DocumentWindowController : NSWindowController <DocumentViewControllerDelegate, DocumentListViewControllerDelegate, DocumentWindowDelegate, NSSplitViewDelegate, NSWindowRestoration>

- (void)toggleNotes;

- (NSString*)baseFolderPath;
- (void)addDocument:(Document*)newDocument;

- (void)showSidebar;
- (IBAction)translateWithGlossaryMenuPressed:(id)sender;
- (IBAction)translateWithGlossaryAndWebPressed:(id)sender;

@end
