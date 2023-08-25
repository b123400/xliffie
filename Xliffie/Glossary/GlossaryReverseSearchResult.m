//
//  GlossaryReverseSearchResult.m
//  Xliffie
//
//  Created by b123400 on 2023/08/01.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "GlossaryReverseSearchResult.h"

@implementation GlossaryReverseSearchResult

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[GlossaryReverseSearchResult class]]) return NO;
    GlossaryReverseSearchResult *r = (GlossaryReverseSearchResult*)object;
    return [self.source isEqual:r.source] && [self.bundlePath isEqual:r.bundlePath];
}

- (NSUInteger)hash {
    return [self.source hash] ^ [self.bundlePath hash];
}

- (id)copyWithZone:(NSZone *)zone {
    GlossaryReverseSearchResult *r = [GlossaryReverseSearchResult new];
    r.source = [self.source copyWithZone:zone];
    r.bundlePath = [self.bundlePath copyWithZone:zone];
    return r;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"GlossaryReverseSearchResult, source = %@, bundlePath = %@", self.source, self.bundlePath];
}

@end
