//
//  GlossarySearchResult.m
//  Xliffie
//
//  Created by b123400 on 2023/08/02.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "GlossarySearchResult.h"

@implementation GlossarySearchResult

- (instancetype)init {
    if (self = [super init]) {
        self.bundlePathSet = [NSMutableOrderedSet orderedSet];
    }
    return self;
}

- (void)addBundlePath:(NSString *)bundlePath {
    [self.bundlePathSet addObject:bundlePath];
}

- (NSArray<NSString *> *)bundlePaths {
    return [self.bundlePathSet array];
}

- (NSNumber *)bundlePathCount {
    return @([self.bundlePaths count]);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"GlossarySearchResult, target = %@, bundlePath = %@", self.target, self.bundlePaths];
}

@end
