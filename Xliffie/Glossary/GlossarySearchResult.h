//
//  GlossarySearchResult.h
//  Xliffie
//
//  Created by b123400 on 2023/08/02.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GlossarySearchResult : NSObject

@property (nonatomic, strong) NSString *target;
@property (nonatomic, strong) NSMutableOrderedSet<NSString*> *bundlePathSet;

- (void)addBundlePath:(NSString *)bundlePath;

- (NSArray<NSString *> *)bundlePaths;

- (NSNumber *)bundlePathCount;

@end

NS_ASSUME_NONNULL_END
