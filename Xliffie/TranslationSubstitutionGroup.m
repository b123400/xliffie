//
//  TranslationSubstitutionGroup.m
//  Xliffie
//
//  Created by b123400 on 2023/10/25.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "TranslationSubstitutionGroup.h"

@implementation TranslationSubstitutionGroup

- (instancetype)initWithSubstitutionToken:(NSString *)token {
    if (self = [super init]) {
        self.substitutionToken = token;
        self.translationPairs = [NSMutableArray array];
    }
    return self;
}

- (void)addPair:(TranslationPair *)pair {
    [self.translationPairs addObject:pair];
}

@end
