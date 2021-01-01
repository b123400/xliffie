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

@interface AppDelegate ()

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

    NSMutableDictionary <NSString*, NSMutableArray <NSString*>*> *basePaths = [NSMutableDictionary dictionary];
    for (NSString *filename in filenames) {
        NSString *basePath = [filename stringByDeletingLastPathComponent];
        NSMutableArray <NSString*> *existingFiles = [basePaths objectForKey:basePath] ?: [NSMutableArray array];
        [existingFiles addObject:filename];
        [basePaths setObject:existingFiles forKey:basePath];
    }

    for (NSString *openingBasePath in basePaths) {
        NSMutableArray <NSString*> *xliffFiles = [basePaths objectForKey:openingBasePath];
        DocumentWindowController *controller = [self openedDocumentControllerWithPath:[xliffFiles firstObject]];
        if (!controller) {
            // open window for this new base path
            NSString *lastFile = [xliffFiles lastObject];
            [xliffFiles removeLastObject];

            [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:lastFile]
                                                                                   display:YES
                                                                         completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {

                                                                             DocumentWindowController *controller = [self openedDocumentControllerWithPath:lastFile];

                                                                             for (NSString *xliffPath in xliffFiles) {
                                                                                 [self attachDocumentOfURL:[NSURL fileURLWithPath:xliffPath]
                                                                                        toWindowController:controller
                                                                                                 withError:&error];
                                                                             }
                                                                         }];
        } else {
            // add document into this window
            for (NSString *xliffPath in xliffFiles) {
                [self attachDocumentOfURL:[NSURL fileURLWithPath:xliffPath]
                       toWindowController:controller
                                withError:nil];
            }
            [[controller window] makeKeyAndOrderFront:self];
        }
    }
}

- (void)attachDocumentOfURL:(NSURL *)url toWindowController:(DocumentWindowController*) controller withError:(NSError**)outError {
    NSString *extension = [[url lastPathComponent] pathExtension];
    Document *newDocument;
    if ([Document isXliffExtension:extension]) {
        newDocument = [[Document alloc] initWithContentsOfURL:url
                                                      ofType:@"xliff"
                                                       error:outError];
    } else if ([XclocDocument isXclocExtension:extension]) {
        newDocument = [[XclocDocument alloc] initWithContentsOfURL:url
                                                            ofType:@"xcloc"
                                                             error:outError];
    }
    [controller setDocument:newDocument];
}

- (DocumentWindowController*)openedDocumentControllerWithPath:(NSString*)filePath {
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

    NSArray *windows = [[NSApplication sharedApplication] windows];
    if (windows.count) {
        [windows[0] makeKeyAndOrderFront:self];
    } else {
        [[NSDocumentController sharedDocumentController] openDocument:self];
    }
    return YES;
}

@end
