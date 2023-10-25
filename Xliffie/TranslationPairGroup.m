//
//  TranslationUnitGroup.m
//  Xliffie
//
//  Created by b123400 on 2023/10/25.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "TranslationPairGroup.h"

@implementation TranslationPairGroup

/// Array of Either<TranslationPair | TranslationPairGroup>
+ (NSArray*)groupsWithTranslationPairs:(NSArray<TranslationPair*>*)pairs {
    NSMutableDictionary<NSString*, TranslationPairGroup*> *idToGroup = [NSMutableDictionary dictionary];
    NSMutableArray *results = [NSMutableArray array];
    for (TranslationPair *pair in pairs) {
        NSString *transUnitId = [pair transUnitIdWithoutModifiers];
        NSDictionary *modifiers = [pair transUnitModifiers];
        if (modifiers.count) {
            TranslationPairGroup *group = idToGroup[transUnitId];
            if (!group) {
                group = idToGroup[transUnitId] = [[TranslationPairGroup alloc] initWithId:transUnitId];
                [results addObject:group];
                
                // It's possible to have id="x" and then id="x|==|modifiers"
                // we have to search for previous existing pair and add it first
                for (id result in results) {
                    if ([result isKindOfClass:[TranslationPair class]]) {
                        TranslationPair *p = (TranslationPair*)result;
                        if ([[p transUnitIdWithoutModifiers] isEqual:transUnitId]) {
                            group.mainPair = p;
                            [results removeObject:result];
                            break;
                        }
                    }
                }
            }
            [group addPair:pair];
        } else {
            [results addObject:pair];
        }
    }
    return results;
}

- (instancetype)initWithId:(NSString *)transUnitId {
    if (self = [super init]) {
        self.transUnitId = transUnitId;
        self.devicePairs = [NSMutableArray array];
        self.substitutionGroups = [NSMutableArray array];
        self.pluralPairs = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initSubstitutionGroupWithPair:(TranslationPair *)pair {
    if (self = [super init]) {
        NSDictionary *modifiers = [pair transUnitModifiers];
        self.transUnitId = [pair transUnitIdWithoutModifiers];
        self.pluralPairs = [NSMutableArray array];
    }
    return self;
}

- (void)addPair:(TranslationPair *)pair {
    NSDictionary *modifiers = [pair transUnitModifiers];
    if (modifiers[@"device"]) {
        [self.devicePairs addObject:pair];
    } else if (modifiers[@"substitutions"]) {
        NSString *token = modifiers[@"substitutions"];
        BOOL addedToGroup = NO;
        for (TranslationSubstitutionGroup *group in self.substitutionGroups) {
            if ([group.substitutionToken isEqual:token]) {
                [group addPair:pair];
                addedToGroup = YES;
                break;
            }
        }
        if (!addedToGroup) {
            TranslationSubstitutionGroup *group = [[TranslationSubstitutionGroup alloc] initWithSubstitutionToken:token];
            [group addPair:pair];
            [self.substitutionGroups addObject:group];
        }
    } else if (modifiers[@"plural"]) {
        [self.pluralPairs addObject:pair];
    }
}

- (NSArray *)children {
    NSMutableArray *results = [NSMutableArray array];
    [results addObjectsFromArray:self.devicePairs];
    [results addObjectsFromArray:self.substitutionGroups];
    [results addObjectsFromArray:self.pluralPairs];
    return results;
}

@end
