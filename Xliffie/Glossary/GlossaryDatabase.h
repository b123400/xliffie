//
//  GlossaryDatabase.h
//  Xliffie
//
//  Created by b123400 on 2023/07/12.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    GlossaryPlatformMac,
    GlossaryPlatformIOS,
} GlossaryPlatform;

@interface GlossaryDatabase : NSObject

@property (nonatomic, assign) GlossaryPlatform platform;
@property (nonatomic, strong) NSString *locale;
@end

NS_ASSUME_NONNULL_END
