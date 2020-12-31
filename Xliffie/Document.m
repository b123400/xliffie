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

- (id)copyWithZone:(nullable NSZone *)zone {
    Document *newDocument = [[[self class] alloc] init];
    newDocument.files = self.files;
    newDocument.xmlDocument = self.xmlDocument;
    newDocument.windowController = self.windowController;
    return newDocument;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

+ (BOOL)autosavesInPlace {
    return YES;
}

+ (BOOL)preservesVersions {
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

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError * _Nullable *)outError {
    NSLog(@"Not applicable");
    return NO;
}

# pragma mark filter

- (Document*)filteredDocumentWithSearchFilter:(NSString*)filter {
    Document *document = [self copy];
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

+ (BOOL)isXliffExtension:(NSString *)extension {
    return [extension isEqualToString:@"xliff"] ||
            [extension isEqualToString:@"xlif"] ||
            [extension isEqualToString:@"xlf"];
}

@end
