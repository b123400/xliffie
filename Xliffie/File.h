//
//  File.h
//  Xliffie
//
//  Created by b123400 on 6/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface File : NSObject

@property (nonatomic, strong) NSString *original;
@property (nonatomic, strong) NSString *sourceLanguage;
@property (nonatomic, strong) NSString *targetLanguage;
@property (nonatomic, strong) NSMutableArray *translations;

- (instancetype)initWithXMLElement:(NSXMLElement*)element;

@end
