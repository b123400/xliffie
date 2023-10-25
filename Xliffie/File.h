//
//  File.h
//  Xliffie
//
//  Created by b123400 on 6/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Document;
@class TranslationPair;

@interface File : NSObject<NSCopying>

// path of the original file, e.g. xx/yy/main.storyboard
@property (nonatomic, strong) NSString *original;

@property (nonatomic, strong) NSString *sourceLanguage;
@property (nonatomic, strong) NSString *targetLanguage;
@property (nonatomic, strong) NSMutableArray <TranslationPair*> *translations;

@property (nonatomic, weak) Document *document;

- (instancetype)initWithXMLElement:(NSXMLElement*)element;

- (File *)filteredFileWithSearchFilter:(NSString*)filter state:(NSUInteger/*TranslationPairState*/)state;
- (NSArray <TranslationPair*> *)translationsMatchingSearchFilter:(NSString*)filter;

- (void)setSourceMapFile:(File*)anotherFile;

- (NSArray *)groupedTranslations;

@end
