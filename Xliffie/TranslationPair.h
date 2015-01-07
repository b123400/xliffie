//
//  TranslationPair.h
//  Xliffie
//
//  Created by b123400 on 6/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TranslationPair : NSObject

@property (nonatomic, strong) NSString *source;
@property (nonatomic, strong) NSString *target;
@property (nonatomic, strong) NSString *note;

- (instancetype)initWithXMLElement:(NSXMLElement*)element;

@end
