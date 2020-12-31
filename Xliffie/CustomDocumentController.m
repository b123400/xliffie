//
//  CustomDocumentController.m
//  Xliffie
//
//  Created by b123400 on 2021/01/01.
//  Copyright © 2021 b123400. All rights reserved.
//

#import "CustomDocumentController.h"
#import "AppDelegate.h"

@implementation CustomDocumentController

+ (void) load
{
    [CustomDocumentController new];
}

- (void)openDocument:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowedFileTypes:@[@"org.oasis-open.xliff"]];
    [panel setCanChooseDirectories:YES];
    [panel beginWithCompletionHandler:^(NSModalResponse result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSArray* urls = [panel URLs];
            AppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
            NSArray *paths = [urls valueForKey:@"path"];
            [appDelegate application:[NSApplication sharedApplication]
                           openFiles:paths];
        }
    }];
}

@end
