//
//  AppDelegate.m
//  Xliffie
//
//  Created by b123400 on 5/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "AppDelegate.h"
#import "DocumentWindowController.h"
#import <Crashlytics/Crashlytics.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [Crashlytics startWithAPIKey:@"be3de76eb1918a93b4d68a8e87b983750d738aed"];
}

- (void)didFinishRestoreWindow:(NSNotification*)notification {
    if (![[NSApplication sharedApplication] windows].count) {
//        [[NSDocumentController sharedDocumentController] openDocument:self];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    BOOL isFolder;
    [[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isFolder];
    if (isFolder) {
        NSError *error=nil;
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filename error:&error];
        if (error) return NO;
        
        NSMutableArray *xliffFiles = [NSMutableArray array];
        
        for (NSString *file in files) {
            if ([[file pathExtension] isEqualToString:@"xliff"] ||
                [[file pathExtension] isEqualToString:@"xlif"] ||
                [[file pathExtension] isEqualToString:@"xlf"]) {
                
                NSURL *thisURL = [NSURL fileURLWithPath:[filename stringByAppendingPathComponent:file]];
                [xliffFiles addObject:thisURL];
            }
        }
        if (!xliffFiles.count) return YES;
        
        // open the first document first, and things later
        // becase we want to make sure they are in the same window
        NSURL *lastURL = [xliffFiles lastObject];
        [xliffFiles removeLastObject];
        [self openFile:lastURL completion:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
            for (NSURL *url in xliffFiles) {
                [self openFile:url];
            }
        }];
        
    } else {
        [self openFile:[NSURL fileURLWithPath:filename]];
    }
    
    return YES;
}

- (void)openFile:(NSURL*)fileURL {
    [self openFile:fileURL completion:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
        
    }];
}

- (void)openFile:(NSURL*)fileURL completion:(void(^)(NSDocument* document, BOOL documentWasAlreadyOpen, NSError *error))complete {
    NSError *error = nil;
    
    for (DocumentWindow *window in [[NSApplication sharedApplication] windows]) {
        DocumentWindowController *controller = (DocumentWindowController*)window.delegate;
        NSString *base = [[controller baseFolderURL] absoluteString];
        if (base && [[fileURL absoluteString] hasPrefix:base]) {
            Document *newDocument = [[Document alloc] initWithContentsOfURL:fileURL
                                                                     ofType:@"xliff"
                                                                      error:&error];
            [controller setDocument:newDocument];
            [controller openDocumentDrawer];
            return;
        }
    }

    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL
                                                                           display:YES completionHandler:complete];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishRestoreWindow:) name:@"NSApplicationDidFinishRestoringWindowsNotification" object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    return NO;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    return YES;
//    NSArray *windows = [[NSApplication sharedApplication] windows];
//    if (windows.count) {
//        [windows[0] makeKeyAndOrderFront:self];
//    } else {
//        [[NSDocumentController sharedDocumentController] openDocument:self];
//    }
//    return NO;
}

@end
