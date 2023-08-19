//
//  Glossary.h
//  Xliffie
//
//  Created by b123400 on 2021/09/27.
//  Copyright © 2021 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Glossary : NSObject

@property (nonatomic, strong) NSString *targetLocale;

+ (instancetype)sharedGlossaryWithLocale:(NSString *)locale;
- (instancetype)initWithTargetLocale:(NSString *)locale;
- (NSArray<NSString *> *)translate:(NSString *)baseString;

@end

NS_ASSUME_NONNULL_END
