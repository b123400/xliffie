//
//  AppDelegate.m
//  Xliffie
//
//  Created by b123400 on 5/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "AppDelegate.h"
#import "DocumentWindowController.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [Fabric with:@[[Crashlytics class]]];
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
        NSString *thisItem = inputs[0];
        [inputs removeObjectAtIndex:0];
        BOOL isFolder;
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:thisItem isDirectory:&isFolder];
        if (exists) {
            if (!isFolder) {
                if ([self isFilePathXliff:thisItem]) {
                    [filenames addObject:thisItem];
                }
            } else {
                NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:thisItem error:nil];
                BOOL isXcloc = [self isFilePathXcloc:thisItem:files];
                
                if (isXcloc) {
                    thisItem = [NSString stringWithFormat:@"%@/%@", thisItem, @"Localized Contents"];
                    files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:thisItem error:nil];
                }

                for (NSString *filename in files) {
                    if ([self isFilePathXliff:filename]) {
                        [inputs addObject:[thisItem stringByAppendingPathComponent:filename]];
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
                                                                             
                                                                             DocumentWindowController *controller = [[document windowControllers] lastObject];
                                                                             
                                                                             for (NSString *xliffPath in xliffFiles) {
                                                                                 Document *newDocument = [[Document alloc] initWithContentsOfURL:[NSURL fileURLWithPath:xliffPath]
                                                                                                                                          ofType:@"xliff"
                                                                                                                                           error:&error];
                                                                                 [controller setDocument:newDocument];
                                                                             }
                                                                             [controller openDocumentDrawer];
                                                                         }];
        } else {
            // add document into this window
            for (NSString *xliffPath in xliffFiles) {
                Document *newDocument = [[Document alloc] initWithContentsOfURL:[NSURL fileURLWithPath:xliffPath]
                                                                         ofType:@"xliff"
                                                                          error:nil];
                [controller setDocument:newDocument];
            }
            [[controller window] makeKeyAndOrderFront:self];
        }
    }
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

- (BOOL)isFilePathXliff:(NSString*)filePath {
    if ([[filePath pathExtension] isEqualToString:@"xliff"] ||
        [[filePath pathExtension] isEqualToString:@"xlif"] ||
        [[filePath pathExtension] isEqualToString:@"xlf"]) {
        return YES;
    }
    return NO;
}

- (BOOL)isFilePathXcloc: (NSString*)filePath : (NSArray*)files {
    BOOL hasLocalizedContents = NO;
    BOOL hasContentsJson = NO;
    BOOL hasSourceContents = NO;
    BOOL hasNotes = NO;

    for (NSString *filename in files) {
        if ([filename isEqualToString:@"Localized Contents"]) {
            hasLocalizedContents = YES;
        }
        
        if ([filename isEqualToString:@"contents.json"]) {
            hasContentsJson = YES;
        }

        if ([filename isEqualToString:@"Source Contents"]) {
            hasSourceContents = YES;
        }

        if ([filename isEqualToString:@"Notes"]) {
            hasNotes = YES;
        }
    }

    if ([[filePath pathExtension] isEqualToString:@"xcloc"] &&
        hasContentsJson &&
        hasLocalizedContents &&
        hasSourceContents &&
        hasNotes) {
        return YES;
    }

    return NO;
}

@end
