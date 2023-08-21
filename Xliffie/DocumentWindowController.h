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
#import "GlossaryDatabase.h"

@interface DocumentWindowController : NSWindowController <DocumentViewControllerDelegate, DocumentWindowDelegate, NSSplitViewDelegate, NSWindowRestoration>

- (void)toggleNotes;
- (void)setFilterState:(TranslationPairState)state;

- (NSString*)path;
- (NSString*)baseFolderPath;

- (GlossaryPlatform)detectedPlatform;
- (NSString *)detectedSourceLocale;
- (NSString *)detectedTargetLocale;

- (IBAction)translateWithGlossaryMenuPressed:(id)sender;
- (IBAction)translateWithGlossaryAndWebPressed:(id)sender;

@end
