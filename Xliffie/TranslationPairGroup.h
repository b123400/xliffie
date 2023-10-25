//
//  TranslationUnitGroup.h
//  Xliffie
//
//  Created by b123400 on 2023/10/25.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TranslationPair.h"
#import "TranslationSubstitutionGroup.h"

NS_ASSUME_NONNULL_BEGIN

@interface TranslationPairGroup : NSObject

@property (nonatomic, strong) NSString *transUnitId;

@property (nonatomic, strong) NSMutableArray<TranslationPair*> *devicePairs;
@property (nonatomic, strong) NSMutableArray<TranslationSubstitutionGroup*> *substitutionGroups;
@property (nonatomic, strong) NSMutableArray<TranslationPair*> *pluralPairs;

// For when there's a pair with exactly the id, and without any modifier
@property (nonatomic, strong) TranslationPair *mainPair;

+ (NSArray*)groupsWithTranslationPairs:(NSArray<TranslationPair*>*)pairs;

// NSArray of Either<TranslationPair | TranslationSubstitutionGroup>
- (NSArray *)children;

@end

NS_ASSUME_NONNULL_END
