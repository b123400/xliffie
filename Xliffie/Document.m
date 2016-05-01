//
//  Document.m
//  Xliffie
//
//  Created by b123400 on 5/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "Document.h"
#import "File.h"
#import "DocumentViewController.h"
#import "DocumentWindowController.h"
#import "AppDelegate.h"

@interface Document ()

@property (nonatomic, strong) NSXMLDocument *xmlDocument;

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
    DocumentWindowController *windowController = [(AppDelegate*)[[NSApplication sharedApplication]
                                                                 delegate]
                                                  openedDocumentControllerWithPath:self.fileURL.path];
    if (windowController) {
        [windowController setDocument:self];
    } else {
        windowController = (DocumentWindowController*)[[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"Document Window Controller"];
        windowController.document = self;
        [self addWindowController:windowController];
    }
    self.windowController = windowController;
    [[windowController window] makeKeyAndOrderFront:self];
    
    // Show Xcode 7.3 sheet
    if ([self isXcode73]) {
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"Do you have Xcode 7.3?",@"xcode alert")];
        [alert setInformativeText:NSLocalizedString(@"Xcode 7.3 has problem with importing XLIFF files, please consider upgrading to a newer version, or go back to Xcode 7.2.\nYou can continue editing, this is just a reminder of a known bug.", @"")];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert addButtonWithTitle:NSLocalizedString(@"OK",@"")];
        [alert addButtonWithTitle:NSLocalizedString(@"Download newer Xcode", @"")];
        [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
        [alert beginSheetModalForWindow:windowController.window
                      completionHandler:^(NSModalResponse returnCode) {
                          if (returnCode == NSAlertSecondButtonReturn) {
                              NSURL *url = [NSURL URLWithString:@"https://developer.apple.com/xcode/download/"];
                              [[NSWorkspace sharedWorkspace] openURL:url];
                          }
                      }];
    }
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // NSLog(@"type name is %@", typeName);
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    return [self.xmlDocument XMLDataWithOptions:NSXMLNodePrettyPrint];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    NSError *error = nil;
    self.xmlDocument = [[NSXMLDocument alloc] initWithData:data options:0 error:&error];
    if (error) {
        *outError = error;
        return NO;
    }
    NSArray *elements = [self.xmlDocument.rootElement elementsForName:@"file"];
    
    for (NSXMLElement *fileElement in elements) {
        File *thisFile = [[File alloc] initWithXMLElement:fileElement];
        thisFile.document = self;
        [self.files addObject:thisFile];
    }
    return YES;
}

# pragma mark filter

- (Document*)filteredDocumentWithSearchFilter:(NSString*)filter {
    Document *document = [[Document alloc] init];
    document.xmlDocument = self.xmlDocument;
    document.files = [self filesMatchingSearchFilter:filter];
    return document;
}

- (NSMutableArray*)filesMatchingSearchFilter:(NSString*)filter {
    NSMutableArray *files = [NSMutableArray array];
    for (File *thisFile in self.files) {
        File *filtered = [thisFile filteredFileWithSearchFilter:filter];
        if (filtered.translations.count) {
            [files addObject:filtered];
        }
    }
    return files;
}

# pragma mark - Tool

- (NSXMLElement*)toolTag {
    NSXMLElement *firstFile = [[self.xmlDocument.rootElement elementsForName:@"file"] firstObject];
    NSXMLElement *fileHeader = [[firstFile elementsForName:@"header"] firstObject];
    NSXMLElement *toolTag = [[fileHeader elementsForName:@"tool"] firstObject];
    return toolTag;
}

- (NSString*)toolID {
    return [[self.toolTag attributeForName:@"tool-id"] stringValue];
}

- (NSString*)toolVersion {
    return [[self.toolTag attributeForName:@"tool-version"] stringValue];
}

- (BOOL)isXcode73 {
    // this version has problem with xliff file
    return [[self toolVersion] isEqualToString:@"7.3"] && [[self toolID] isEqualToString:@"com.apple.dt.xcode"];
}

@end
