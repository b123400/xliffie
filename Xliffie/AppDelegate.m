//
//  AppDelegate.m
//  Xliffie
//
//  Created by b123400 on 5/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "AppDelegate.h"
#import "DocumentWindowController.h"
#import "XclocDocument.h"
#import "Glossary.h"
#import "GlossaryManagerWindowController.h"

@interface AppDelegate ()

@property (nonatomic, strong) GlossaryManagerWindowController *glossaryManagerWindowController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)didFinishRestoreWindow:(NSNotification*)notification {
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    [self application:theApplication openFiles:@[filename]];
    return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray<NSString *> *)inputFilenames {

    NSMutableArray *inputs = [NSMutableArray arrayWithArray:inputFilenames];
    NSMutableArray *filenames = [NSMutableArray array];

    while ([inputs count]) {
        NSString *thisItem = [inputs firstObject];
        [inputs removeObjectAtIndex:0];
        BOOL isFolder;
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:thisItem isDirectory:&isFolder];
        if (exists) {
            if (!isFolder) {
                if ([Document isXliffExtension:[thisItem pathExtension]]) {
                    [filenames addObject:thisItem];
                }
            } else {
                NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:thisItem error:nil];
                BOOL isXcloc = [XclocDocument isXclocExtension:[thisItem pathExtension]];

                if (isXcloc) {
                    [filenames addObject:thisItem];
                } else {
                    for (NSString *filename in files) {
                        if ([Document isXliffExtension:[filename pathExtension]] || [XclocDocument isXclocExtension:[filename pathExtension]]) {
                            [inputs addObject:[thisItem stringByAppendingPathComponent:filename]];
                        }
                    }
                }
            }
        }
    }

    for (NSString *filename in filenames) {
        DocumentWindowController *existingController = [self openedDocumentControllerWithPath:filename];
        if (existingController) {
            [existingController.window makeKeyAndOrderFront:self];
            continue;
        }
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filename]
                                                                               display:YES
                                                                     completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
            DocumentWindowController *thisController = [(Document*)document windowController];
            DocumentWindowController *anotherController = [self openedDocumentControllerWithBasePath:filename];
            if (anotherController && anotherController != thisController) {
                [anotherController.window addTabbedWindow:thisController.window ordered:NSWindowAbove];
                [anotherController.window selectNextTab:nil];
            } else {
                [thisController.window makeKeyAndOrderFront:nil];
            }
        }];
    }
}

- (DocumentWindowController*)openedDocumentControllerWithPath:(NSString*)filePath {
    for (DocumentWindow *window in [[NSApplication sharedApplication] windows]) {
        if (![window isKindOfClass:[DocumentWindow class]]) continue;
        DocumentWindowController *controller = (DocumentWindowController*)[window windowController];
        if ([filePath isEqualToString:[controller path]]) {
            return controller;
        }
    }
    return nil;
}

- (DocumentWindowController*)openedDocumentControllerWithBasePath:(NSString*)filePath {
    for (DocumentWindow *window in [[NSApplication sharedApplication] windows]) {
        if (![window isKindOfClass:[DocumentWindow class]]) continue;
        DocumentWindowController *controller = (DocumentWindowController*)[window windowController];
        NSString *basePath = [controller baseFolderPath];
        if ([[filePath stringByDeletingLastPathComponent] isEqualToString:basePath]) {
            return controller;
        }
    }
    return nil;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishRestoreWindow:) name:@"NSApplicationDidFinishRestoringWindowsNotification" object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    if (![[NSApplication sharedApplication] windows].count) {
        [[NSDocumentController sharedDocumentController] openDocument:self];
    }
    return NO;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {

    NSWindow *window = [[NSApplication sharedApplication] keyWindow];
    if (window) {
        [window makeKeyAndOrderFront:self];
    } else {
        [[NSDocumentController sharedDocumentController] openDocument:self];
    }
    return YES;
}

- (DocumentWindowController *)firstDocumentController {
    NSWindow *window = [NSApplication sharedApplication].keyWindow;
    if ([window.delegate isKindOfClass:[DocumentWindowController class]]) {
        return (DocumentWindowController*)window.delegate;
    }
    return nil;
}

#pragma mark - Menu bar

- (IBAction)translateWithGlossaryMenuPressed:(id)sender {
    DocumentWindowController *controller = (DocumentWindowController*)[[[NSApplication sharedApplication] keyWindow] delegate];
    if (![controller isKindOfClass:[DocumentWindowController class]]) {
        return;
    }
    [controller translateWithGlossaryMenuPressed:sender];
}
- (IBAction)translateWithGlossaryAndWebPressed:(id)sender {
    DocumentWindowController *controller = (DocumentWindowController*)[[[NSApplication sharedApplication] keyWindow] delegate];
    if (![controller isKindOfClass:[DocumentWindowController class]]) {
        return;
    }
    [controller translateWithGlossaryAndWebPressed:sender];
}

- (IBAction)glossaryMenuPressed:(id)sender {
    if (!self.glossaryManagerWindowController) {
        self.glossaryManagerWindowController = [[GlossaryManagerWindowController alloc] init];
    }
    [self.glossaryManagerWindowController showWindow:self];
}

@end
