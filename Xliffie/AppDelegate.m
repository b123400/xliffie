//
//  AppDelegate.m
//  Xliffie
//
//  Created by b123400 on 5/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "AppDelegate.h"
#import "DocumentWindowController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    if (![[NSApplication sharedApplication] windows].count) {
        [[NSDocumentController sharedDocumentController] openDocument:self];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    NSArray *windows = [[NSApplication sharedApplication] windows];
    if (windows.count) {
        [windows[0] makeKeyAndOrderFront:self];
    } else {
        [[NSDocumentController sharedDocumentController] openDocument:self];
    }
    return NO;
}

@end
