//
//  File.m
//  Xliffie
//
//  Created by b123400 on 6/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "File.h"
#import "TranslationPair.h"
#import "Document.h"

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
    for (NSXMLElement *unit in [self getNestedTransUnitElements:bodyElement]) {
        TranslationPair *pair = [[TranslationPair alloc] initWithXMLElement:unit];
        pair.file = self;
        [self.translations addObject:pair];
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    File *newFile = [[File allocWithZone:zone] initWithXMLElement:self.xmlElement];
    newFile.document = self.document;
    return newFile;
}

- (NSArray <NSXMLElement*> *)getNestedTransUnitElements:(NSXMLElement *)bodyElement {
    if ([[bodyElement name] isEqualToString:@"group"] && [[[bodyElement attributeForName:@"translate"] stringValue] isEqualToString:@"no"]) {
        return @[];
    }
    NSMutableArray *elements = [NSMutableArray array];
    [elements addObjectsFromArray:[bodyElement elementsForName:@"trans-unit"]];
    for (NSXMLElement *groupElement in [bodyElement elementsForName:@"group"]) {
        [elements addObjectsFromArray:[self getNestedTransUnitElements:groupElement]];
    }
    NSMutableArray <NSXMLElement*> *toRemove = [NSMutableArray array];
    for (NSXMLElement *element in elements) {
        if ([[[element attributeForName:@"translate"] stringValue] isEqualToString:@"no"]) {
            [toRemove addObject:element];
        }
    }
    [elements removeObjectsInArray:toRemove];
    return elements;
}

- (File *)filteredFileWithSearchFilter:(NSString*)filter state:(NSUInteger)state {
    TranslationPairState pairState = (TranslationPairState)state;
    File *newFile = [self copy];
    newFile.translations = [NSMutableArray array];
    for (TranslationPair *pair in [self translationsMatchingSearchFilter:filter]) {
        if (state == 0 || pair.state & pairState) {
            [newFile.translations addObject:pair];
        }
    }
    return newFile;
}

- (NSArray <TranslationPair*> *)translationsMatchingSearchFilter:(NSString*)filter {
    if (!filter.length) return [self.translations copy];
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
    if ([_targetLanguage isEqualToString:targetLanguage]) return;
    if ([targetLanguage isEqualToString:@""]) {
        targetLanguage = nil;
    }
    if (self.xmlElement) { // make sure it is after init
        [[self.document undoManager] registerUndoWithTarget:self
                                                   selector:@selector(setTargetLanguage:)
                                                     object:_targetLanguage];
    }
    _targetLanguage = targetLanguage;
    NSXMLNode *targetAttribute = [self.xmlElement attributeForName:@"target-language"];
    if (!targetAttribute) {
        targetAttribute = [NSXMLNode attributeWithName:@"target-language" stringValue:targetLanguage];
        [self.xmlElement addAttribute:targetAttribute];
    } else {
        [targetAttribute setStringValue:targetLanguage];
    }
}

@end
