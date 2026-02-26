//
//  Utilities.h
//  Xliffie
//
//  Created by b123400 on 2023/08/09.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    StringFormatAllUpper,
    StringFormatInitialUpper,
    StringFormatAllLower,
    StringFormatUnknown,
} StringFormat;

@interface Utilities : NSObject

+ (NSArray *)batch:(NSArray *)items limit:(NSInteger)limit callback:(id (^)(NSArray *items))callback;

+ (StringFormat)detectFormatOfString:(NSString *)string;
+ (NSString *)applyFormat:(StringFormat)format toString:(NSString *)string;
+ (NSString *)applyFormatOfString:(NSString *)formatString toString:(NSString *)targetString;

+ (NSString *)stringForDevice:(NSString *)deviceString;

+ (void)refillMenu:(NSMenu *)result withAllAvailableLocalesWithTarget:(id)target action:(SEL)action;

+ (NSString *)displayNameForLocaleIdentifier:(NSString *)identifier;

+ (NSArray<NSString*> *)fallbacksWithLocale:(NSString * _Nullable )localeCode;

@end

NS_ASSUME_NONNULL_END
