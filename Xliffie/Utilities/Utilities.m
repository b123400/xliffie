//
//  Utilities.m
//  Xliffie
//
//  Created by b123400 on 2023/08/09.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "Utilities.h"
#import "LanguageSet.h"

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

+ (NSMenu *)menuOfAllAvailableLocalesWithTarget:(id)target action:(SEL)action {
    NSMenu *result = [[NSMenu alloc] init];
    NSMutableArray <LanguageSet*> *targetLanguages = [[NSMutableArray alloc] init];
    
    for (NSString *localeIdentifier in [[NSLocale availableLocaleIdentifiers] sortedArrayUsingSelector:@selector(compare:)]) {
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:localeIdentifier];
        NSString *thisLanguageCode = [locale objectForKey:NSLocaleLanguageCode];
        NSString *thisLanguageScript = [locale objectForKey:NSLocaleScriptCode];
        
        LanguageSet *lastLanguageSet = [targetLanguages lastObject];
        NSString *lastLanguageIdentifier = [lastLanguageSet mainLanguage];
        NSLocale *lastLocale = [NSLocale localeWithLocaleIdentifier:lastLanguageIdentifier];
        NSString *lastLanguageCode = [lastLocale objectForKey:NSLocaleLanguageCode];
        NSString *lastLanguageScript = [lastLocale objectForKey:NSLocaleScriptCode];
        
        if (![lastLanguageCode isEqualToString:thisLanguageCode] ||
            ([lastLanguageCode isEqualToString:thisLanguageCode] &&
             thisLanguageScript &&
             ![lastLanguageScript isEqualToString:thisLanguageScript])) {
            
            // make new language set
            LanguageSet *thisLanguageSet = [[LanguageSet alloc] init];
            thisLanguageSet.mainLanguage = localeIdentifier;
            [targetLanguages addObject:thisLanguageSet];
            
        } else {
            // this code is same as last code, means this is a sub-language of the last one
            // like: zh_Hant -> zh_Hang_HK
            [lastLanguageSet.subLanguages addObject:localeIdentifier];
        }
    }
    [targetLanguages sortUsingComparator:^NSComparisonResult(LanguageSet *obj1, LanguageSet *obj2) {
        NSString *displayName1 = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                                       value:obj1.mainLanguage];
        NSString *displayName2 = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                                       value:obj2.mainLanguage];
        return [displayName1 compare:displayName2];
    }];
    
    for (LanguageSet *languageSet in targetLanguages) {
        NSString *languageName = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                                       value:languageSet.mainLanguage];
        NSMenuItem *thisItem = [[NSMenuItem alloc] initWithTitle:languageName
                                                          action:action
                                                   keyEquivalent:@""];
        thisItem.target = target;
        thisItem.representedObject = languageSet.mainLanguage;
        
        if (languageSet.subLanguages.count) {
            // one more same item in sub menu
            NSMenu *subMenu = [[NSMenu alloc] init];
            [thisItem setSubmenu:subMenu];
            NSMenuItem *subItem = [[NSMenuItem alloc] initWithTitle:languageName
                                                              action:action
                                                       keyEquivalent:@""];
            subItem.target = target;
            subItem.representedObject = languageSet.mainLanguage;
            [subMenu addItem:subItem];
            
            // all sub languages
            for (NSString *subLanguage in languageSet.subLanguages) {
                NSString *subLanguageName = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                                                  value:subLanguage];
                NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:subLanguageName
                                                              action:action
                                                       keyEquivalent:@""];
                item.target = target;
                item.representedObject = subLanguage;
                [subMenu addItem:item];
            }
        }
        
        [result addItem:thisItem];
    }
    
    // preferred language in systems
    if ([[NSLocale preferredLanguages] count] > 0) {
        [result insertItem:[NSMenuItem separatorItem] atIndex:0];
        // more likely to be selected, so put to top
        for (NSString *preferredLangaugeIdentifier in [[NSLocale preferredLanguages] reverseObjectEnumerator]) {
            NSString *preferredLanguage = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                                                value:preferredLangaugeIdentifier];
            
            NSMenuItem *menuItem = [result insertItemWithTitle:preferredLanguage
                                                        action:action
                                                 keyEquivalent:@""
                                                       atIndex:0];
            menuItem.target = target;
            menuItem.representedObject = preferredLangaugeIdentifier;
        }
    }
    return result;
}

@end
