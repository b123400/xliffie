//
//  File.m
//  Xliffie
//
//  Created by b123400 on 6/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "File.h"
#import "TranslationPair.h"

@interface File ()

@property (nonatomic, strong) NSXMLElement *xmlElement;

@end

@implementation File

- (instancetype) initWithXMLElement:(NSXMLElement*)element {
    self = [super init];
    
    self.xmlElement = element;
    self.original = [[element attributeForName:@"original"] stringValue];
    NSString *sourceCode = [[element attributeForName:@"source-language"] stringValue];
    NSString *targetCode = [[element attributeForName:@"target-language"] stringValue];
    
    self.sourceLanguage = sourceCode;
    self.targetLanguage = targetCode;
    
    self.translations = [NSMutableArray array];
    
    NSXMLElement *bodyElement = [[element elementsForName:@"body"] firstObject];
    for (NSXMLElement *unit in [bodyElement elementsForName:@"trans-unit"]) {
        TranslationPair *pair = [[TranslationPair alloc] initWithXMLElement:unit];
        pair.file = self;
        [self.translations addObject:pair];
    }
    return self;
}

- (File *)filteredFileWithSearchFilter:(NSString*)filter {
    File *newFile = [[File alloc] initWithXMLElement:self.xmlElement];
    newFile.translations = [NSMutableArray array];
    for (TranslationPair *pair in [self translationsMatchingSearchFilter:filter]) {
        [newFile.translations addObject:pair];
    }
    return newFile;
}

- (NSArray *)translationsMatchingSearchFilter:(NSString*)filter {
    return [self.translations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject matchSearchFilter:filter];
    }]];
}

- (void)setSourceMapFile:(File*)anotherFile {
    NSMutableDictionary *sourceMap = [NSMutableDictionary dictionary];
    if (anotherFile) {
        for (TranslationPair *pair in anotherFile.translations) {
            [sourceMap setObject:pair forKey:pair.source];
        }
    }
    for (TranslationPair *pair in self.translations) {
        pair.alternativePair = sourceMap[pair.source];
    }
}

#pragma mark property

- (void)setTargetLanguage:(NSString *)targetLanguage {
    NSXMLNode *targetAttribute = [self.xmlElement attributeForName:@"target-language"];
    if (!targetAttribute) {
        targetAttribute = [NSXMLNode attributeWithName:@"target-language" stringValue:targetLanguage];
        [self.xmlElement addAttribute:targetAttribute];
    } else {
        [targetAttribute setStringValue:targetLanguage];
    }
    _targetLanguage = targetLanguage;
}

@end
