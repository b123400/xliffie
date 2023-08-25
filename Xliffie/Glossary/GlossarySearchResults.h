//
//  GlossarySearchResults.h
//  Xliffie
//
//  Created by b123400 on 2023/08/02.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GlossarySearchRow.h"
#import "GlossarySearchResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface GlossarySearchResults : NSObject

- (void)addSearchResults:(NSArray<GlossarySearchRow*>*)results;
- (void)addResultWithSource:(NSString *)source target:(NSString *)target bundlePath:(NSString *)bundlePath;

- (NSArray<GlossarySearchResult*> *)targetsWithSource:(NSString *)source;

@end

NS_ASSUME_NONNULL_END
