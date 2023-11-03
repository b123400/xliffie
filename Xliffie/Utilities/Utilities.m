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

+ (StringFormat)detectFormatOfString:(NSString *)string {
    if ([string length] <= 2) return StringFormatUnknown;
    BOOL isAllUpper = YES;
    BOOL isAllLower = YES;
    BOOL isPrevSpace = YES;
    BOOL isFirstCap = YES;
    for (NSUInteger i = 0; i < [string length]; i++) {
        unichar character = [string characterAtIndex:i];
        BOOL isWhitespace = [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:character];
        BOOL isLower = [[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:character];
        BOOL isUpper = [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:character];
        if (!isLower && !isWhitespace) {
            isAllLower = NO;
        }
        if (!isUpper && !isWhitespace) {
            isAllUpper = NO;
        }
        if (isPrevSpace && !isUpper && !isWhitespace) {
            isFirstCap = NO;
        } else if (!isPrevSpace && !isLower && !isWhitespace) {
            isFirstCap = NO;
        }
        isPrevSpace = isWhitespace;
    }
    if (isFirstCap) return StringFormatInitialUpper;
    if (isAllUpper) return StringFormatAllUpper;
    if (isAllLower) return StringFormatAllLower;
    return StringFormatUnknown;
}

+ (NSString *)applyFormat:(StringFormat)format toString:(NSString *)string {
    switch (format) {
        case StringFormatInitialUpper:
            return [string capitalizedString];
        case StringFormatAllLower:
            return [string lowercaseString];
        case StringFormatAllUpper:
            return [string uppercaseString];
        case StringFormatUnknown:
            return string;
    }
}

+ (NSString *)applyFormatOfString:(NSString *)formatString toString:(NSString *)targetString {
    return [Utilities applyFormat:[Utilities detectFormatOfString:formatString] toString:targetString];
}

+ (NSString *)stringForDevice:(NSString *)deviceString {
    if ([deviceString isEqual:@"iphone"]) {
        return @"􀟜 iPhone";
    } else if ([deviceString isEqual:@"mac"]) {
        return @"􀙗 Mac";
    } else if ([deviceString isEqual:@"appletv"]) {
        return @"􀡴 Apple TV";
    } else if ([deviceString isEqual:@"applevision"]) {
        return @"Apple Vision";
    } else if ([deviceString isEqual:@"applewatch"]) {
        return @"􀟤 Apple Watch";
    } else if ([deviceString isEqual:@"ipad"]) {
        return @"􀟠 iPad";
    } else if ([deviceString isEqual:@"ipod"]) {
        return @"􀢺 iPod";
    }
    return nil;
}

@end
