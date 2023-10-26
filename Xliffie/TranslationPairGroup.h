//
//  TranslationUnitGroup.h
//  Xliffie
//
//  Created by b123400 on 2023/10/25.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TranslationPair.h"

NS_ASSUME_NONNULL_BEGIN

@interface TranslationPairGroup : NSObject

@property (nonatomic, strong) NSMutableArray *children;

// For when there's a pair with exactly the id, and without any modifier
@property (nonatomic, nullable, strong) TranslationPair *mainPair;
@property (nonatomic, nullable, strong) NSString *pathName;

@property (nonatomic, nullable, strong) NSString *groupModifierKey;

+ (NSArray*)groupsWithTranslationPairs:(NSArray<TranslationPair*>*)pairs;

- (NSString *)transUnitIdWithoutModifiers;

- (id)stringForSourceColumn;

@end

NS_ASSUME_NONNULL_END
