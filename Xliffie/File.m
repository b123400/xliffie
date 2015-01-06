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

@property (nonatomic, strong) RXMLElement *xmlElement;

@end

@implementation File

- (instancetype) initWithXMLElement:(RXMLElement*)element {
    self = [super init];
    
    self.xmlElement = element;
    self.original = [element attribute:@"original"];
    self.translations = [NSMutableArray array];
    
    [element iterate:@"body.trans-unit" usingBlock:^(RXMLElement *unit) {
        TranslationPair *pair = [[TranslationPair alloc] initWithXMLElement:unit];
        [self.translations addObject:pair];
    }];
    return self;
}

@end
