//
//  Utilities.h
//  Xliffie
//
//  Created by b123400 on 2023/08/09.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Utilities : NSObject

+ (NSArray *)batch:(NSArray *)items limit:(NSInteger)limit callback:(id (^)(NSArray *items))callback;

@end

NS_ASSUME_NONNULL_END
