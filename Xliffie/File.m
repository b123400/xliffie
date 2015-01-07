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
    self.translations = [NSMutableArray array];
    
    NSXMLElement *bodyElement = [[element elementsForName:@"body"] firstObject];
    for (NSXMLElement *unit in [bodyElement elementsForName:@"trans-unit"]) {
        TranslationPair *pair = [[TranslationPair alloc] initWithXMLElement:unit];
        [self.translations addObject:pair];
    }
    return self;
}

@end
