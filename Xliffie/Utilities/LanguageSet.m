//
//  LanguageSet.m
//  Xliffie
//
//  Created by b123400 on 2024/02/08.
//  Copyright © 2024 b123400. All rights reserved.
//

#import "LanguageSet.h"

@implementation LanguageSet
- (id)init {
    self = [super init];
    self.subLanguages = [NSMutableArray array];
    return self;
}
@end
