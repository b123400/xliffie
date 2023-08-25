//
//  GlossarySearchResult.h
//  Xliffie
//
//  Created by b123400 on 2023/08/01.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GlossarySearchRow : NSObject<NSCopying>

@property (nonatomic, strong) NSString *source;
@property (nonatomic, strong) NSString *target;
@property (nonatomic, strong) NSString *bundlePath;

@end

NS_ASSUME_NONNULL_END
