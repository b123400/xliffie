//
//  Document.h
//  Xliffie
//
//  Created by b123400 on 5/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "File.h"
#import "TranslationPair.h"

@class DocumentWindowController;

@interface Document : NSDocument<NSCopying>

@property (nonatomic, strong) NSMutableArray <File*> *files;
@property (nonatomic, strong) DocumentWindowController *windowController;

- (Document*)filteredDocumentWithSearchFilter:(NSString*)filter state:(TranslationPairState)state;
- (NSMutableArray*)filesMatchingSearchFilter:(NSString*)filter state:(TranslationPairState)state;

- (NSString*)toolID;
- (NSString*)toolVersion;

+ (BOOL)isXliffExtension:(NSString *)extension;
- (NSArray <TranslationPair*> *)allTranslationPairs;

@end
