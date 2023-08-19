//
//  GlossarySearchResults.m
//  Xliffie
//
//  Created by b123400 on 2023/08/02.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "GlossarySearchResults.h"
#import "Utilities.h"

@interface GlossarySearchResults ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, GlossarySearchResult *>*> *results;

@end

@implementation GlossarySearchResults

- (instancetype)init {
    if (self = [super init]) {
        self.results = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addSearchResults:(NSArray<GlossarySearchRow*>*)results {
    for (GlossarySearchRow *row in results) {
        [self addResultWithSource:row.source target:row.target bundlePath:row.bundlePath];
    }
}

- (void)addResultWithSource:(NSString *)source target:(NSString *)target bundlePath:(NSString *)bundlePath {
    target = [Utilities applyFormatOfString:source toString:target];
    source = [source lowercaseString];
    if (!self.results[source]) {
        self.results[source] = [NSMutableDictionary dictionary];
    }
    NSMutableDictionary<NSString *, GlossarySearchResult*> *targets = self.results[source];
    if (!targets[target]) {
        targets[target] = [GlossarySearchResult new];
        targets[target].target = target;
    }
    [targets[target] addBundlePath:bundlePath];
}

- (NSArray<GlossarySearchResult*> *)targetsWithSource:(NSString *)source {
    source = [source lowercaseString];
    source = [source stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableDictionary<NSString *, GlossarySearchResult*> *targets = self.results[source];
    NSArray *r = [[targets allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"bundlePathCount" ascending:NO]]];
    return r;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"GlossarySearchResults %@", self.results];
}

@end
