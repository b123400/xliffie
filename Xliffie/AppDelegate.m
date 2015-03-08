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
        
        for (NSString *file in files) {
            if ([[file pathExtension] isEqualToString:@"xliff"] ||
                [[file pathExtension] isEqualToString:@"xlif"] ||
                [[file pathExtension] isEqualToString:@"xlf"]) {
                
                NSURL *thisURL = [NSURL fileURLWithPath:[filename stringByAppendingPathComponent:file]];
                [self openFile:thisURL];
            }
        }
    } else {
        [self openFile:[NSURL fileURLWithPath:filename]];
    }
    
    return YES;
}

- (void)openFile:(NSURL*)fileURL {
    NSError *error = nil;
    
    for (DocumentWindow *window in [[NSApplication sharedApplication] windows]) {
        DocumentWindowController *controller = (DocumentWindowController*)window.delegate;
        if ([[fileURL absoluteString] hasPrefix:[[controller baseFolderURL] absoluteString]]) {
            Document *newDocument = [[Document alloc] initWithContentsOfURL:fileURL
                                                                     ofType:@"xliff"
                                                                      error:&error];
            [controller addDocument:newDocument];
            return;
        }
    }

    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL
                                                                           display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
                                                                               
                                                                           }];
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
