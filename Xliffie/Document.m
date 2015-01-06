//
//  Document.m
//  Xliffie
//
//  Created by b123400 on 5/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "Document.h"
#import "File.h"
#import <RaptureXML/RXMLElement.h>
#import "ViewController.h"

@interface Document ()

@end

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        self.files = [NSMutableArray array];
    }
    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (void)makeWindowControllers {
    // Override to return the Storyboard file name of the document.
    NSWindowController *windowController = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"Document Window Controller"];
    ViewController *vc = (ViewController*)windowController.contentViewController;
    [self addWindowController:windowController];
    vc.document = self;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // NSLog(@"type name is %@", typeName);
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    RXMLElement *root = [RXMLElement elementFromXMLData:data];
    NSArray *files = [root children:@"file"];
    for (RXMLElement *fileElement in files) {
        File *thisFile = [[File alloc] initWithXMLElement:fileElement];
        [self.files addObject:thisFile];
    }
    return YES;
}

@end
