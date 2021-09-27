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

- (instancetype)initWithTargetLocale:(NSString *)locale;
- (NSString *)translate:(NSString *)baseString isMenu:(BOOL)isMenu;

@end

NS_ASSUME_NONNULL_END
