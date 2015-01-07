//
//  TranslationPair.m
//  Xliffie
//
//  Created by b123400 on 6/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "TranslationPair.h"

@interface TranslationPair ()

@property (nonatomic, strong) NSXMLElement *xmlElement;

@end

@implementation TranslationPair

- (instancetype)initWithXMLElement:(NSXMLElement*)element {
    self = [super init];
    
    self.xmlElement = element;
    
    self.source = [[[element elementsForName:@"source"] firstObject] stringValue];
    self.target = [[[element elementsForName:@"target"] firstObject] stringValue];
    self.note = [[[element elementsForName:@"note"] firstObject] stringValue];
    
    return self;
}

@end
