//
//  TranslationSubstitutionGroup.h
//  Xliffie
//
//  Created by b123400 on 2023/10/25.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TranslationPair.h"

NS_ASSUME_NONNULL_BEGIN

@interface TranslationSubstitutionGroup : NSObject

@property (nonatomic, strong) NSMutableArray<TranslationPair *> *translationPairs;

@property (nonatomic, strong) NSString *substitutionToken;

- (instancetype)initWithSubstitutionToken:(NSString *)token;

- (void)addPair:(TranslationPair *)pair;

@end

NS_ASSUME_NONNULL_END
