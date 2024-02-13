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

+ (NSMenu *)menuOfAllAvailableLocalesWithTarget:(id)target action:(SEL)action;

+ (NSArray<NSString*> *)fallbacksWithLocale:(NSString*)localeCode;

@end

NS_ASSUME_NONNULL_END
