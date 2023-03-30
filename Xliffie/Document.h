//
//  Document.h
//  Xliffie
//
//  Created by b123400 on 5/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "File.h"

@class DocumentWindowController;

@interface Document : NSDocument<NSCopying>

@property (nonatomic, strong) NSMutableArray <File*> *files;
@property (nonatomic, strong) DocumentWindowController *windowController;

- (Document*)filteredDocumentWithSearchFilter:(NSString*)filter;
- (NSMutableArray*)filesMatchingSearchFilter:(NSString*)filter;

- (NSString*)toolID;
- (NSString*)toolVersion;

+ (BOOL)isXliffExtension:(NSString *)extension;
- (NSArray <TranslationPair*> *)allTranslationPairs;

@end
