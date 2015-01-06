//
//  TranslationPair.m
//  Xliffie
//
//  Created by b123400 on 6/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "TranslationPair.h"

@interface TranslationPair ()

@property (nonatomic, strong) RXMLElement *xmlElement;

@end

@implementation TranslationPair

- (instancetype)initWithXMLElement:(RXMLElement*)element {
    self = [super init];
    
    self.xmlElement = element;
    
    self.source = [element child:@"source"].text;
    self.target = [element child:@"target"].text;
    self.note = [element child:@"note"].text;
    
    return self;
}

@end
