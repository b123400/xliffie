//
//  AppDelegate.h
//  Xliffie
//
//  Created by b123400 on 5/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DocumentWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

- (DocumentWindowController*)openedDocumentControllerWithPath:(NSString*)filePath;

@end

