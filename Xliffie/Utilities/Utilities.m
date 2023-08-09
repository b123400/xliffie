//
//  Utilities.m
//  Xliffie
//
//  Created by b123400 on 2023/08/09.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "Utilities.h"

@implementation Utilities

+ (NSArray *)batch:(NSArray *)items limit:(NSInteger)limit callback:(id (^)(NSArray *items))callback {
    NSMutableArray *results = [NSMutableArray array];
    NSInteger index = 0;
    while (index < items.count) {
        NSRange range = NSMakeRange(index, MIN(items.count - index, limit));
        if (index > items.count - 1) break;
        NSArray *thisBatch = [items subarrayWithRange:range];
        id result = callback(thisBatch);
        [results addObject:result];
        index += limit;
    }
    return results;
}


@end
