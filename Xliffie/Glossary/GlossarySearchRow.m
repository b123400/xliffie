//
//  GlossarySearchResult.m
//  Xliffie
//
//  Created by b123400 on 2023/08/01.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "GlossarySearchRow.h"

@implementation GlossarySearchRow

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[GlossarySearchRow class]]) return NO;
    GlossarySearchRow *r = (GlossarySearchRow*)object;
    return [self.source isEqual:r.source] && [self.target isEqual:r.target] && [self.bundlePath isEqual:r.bundlePath];
}

- (NSUInteger)hash {
    return [self.source hash] ^ [self.target hash] ^ [self.bundlePath hash];
}

- (id)copyWithZone:(NSZone *)zone {
    GlossarySearchRow *r = [GlossarySearchRow new];
    r.source = [self.source copyWithZone:zone];
    r.target = [self.target copyWithZone:zone];
    r.bundlePath = [self.bundlePath copyWithZone:zone];
    return r;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"GlossarySearchRow, source = %@ target = %@, bundlePath = %@", self.source, self.target, self.bundlePath];
}

@end
