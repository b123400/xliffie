//
//  Glossary.m
//  Xliffie
//
//  Created by b123400 on 2021/09/27.
//  Copyright © 2021 b123400. All rights reserved.
//

#import "Glossary.h"
#import "Utilities.h"

@interface Glossary ()
@property (nonatomic, strong) NSDictionary<NSString*, NSDictionary<NSString *, NSArray<NSString *>*>*> *translationDict;
@end

@implementation Glossary

+ (instancetype)sharedGlossaryWithLocale:(NSString *)locale {
    static Glossary *shared = nil;
    if (![Glossary supportedLocale:locale]) return nil;
    if (!shared || ![shared.targetLocale isEqualTo:locale]) {
        shared = [[Glossary alloc] initWithTargetLocale:locale];
    }
    return shared;
}

- (instancetype)initWithTargetLocale:(NSString *)locale {
    if (self = [super init]) {
        self.targetLocale = [Glossary supportedLocale:locale];
        if (self.targetLocale) {
            [self setupTranslationDict];
        } else {
            return nil;
        }
    }
    return self;
}

- (void)setupTranslationDict {
    NSURL *url = [[NSBundle mainBundle] URLForResource:self.targetLocale withExtension:@"glossary"];
    NSError *error = nil;
    NSData *glossaryData = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (error) {
        NSLog(@"error %@", error.description);
        return;
    }
    self.translationDict = [NSJSONSerialization JSONObjectWithData:glossaryData options:0 error:&error];
    if (error) {
        NSLog(@"error %@", error.description);
        return;
    }
}

+ (NSArray<NSString *> *)glossaryFilenames {
    return @[
        @"ar", @"ca", @"cs", @"da", @"de", @"el", @"en_au", @"en_gb", @"es_419",
        @"es", @"fi", @"fr_ca", @"fr", @"he", @"hi", @"hr", @"hu", @"id", @"it",
        @"ja", @"ko", @"ms", @"nl", @"no", @"pl", @"pt_br", @"pt_pt", @"ro", @"ru",
        @"sk", @"sv", @"th", @"tr", @"uk", @"vi", @"zh_cn", @"zh_hk", @"zh_tw",
    ];
}

+ (NSString *)supportedLocale:(NSString *)locale {
    NSArray<NSString *> *supportedLocales = [Glossary glossaryFilenames];
    NSArray<NSString *> *locales = [[Glossary fallbacksWithLocale:locale] valueForKey:@"lowercaseString"];
    for (NSString *thisLocale in locales) {
        if ([supportedLocales containsObject:thisLocale]) {
            return thisLocale;
        }
        if ([thisLocale isEqualTo:@"zh"]) {
            return @"zh_hk";
        }
    }
    return nil;
}

/**
 * Generates a list of fallback locale code, e.g.
 * Input: zh_Hant_HK
 * Outout: [zh-Hant-HK, zh-HK, zh-Hant, zh]
 */
+ (NSArray<NSString*> *)fallbacksWithLocale:(NSString*)localeCode {
    NSArray *components = [localeCode.lowercaseString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"_-"]];
    NSMutableOrderedSet *result = [NSMutableOrderedSet orderedSet];
    [result addObject:[components componentsJoinedByString:@"_"]];
    if (components.count >= 2) {
        [result addObject:[NSString stringWithFormat:@"%@_%@", components.firstObject, components.lastObject]];
    }
    for (NSInteger i = components.count; i >= 1; i--) {
        [result addObject:[[components subarrayWithRange:NSMakeRange(0, i)] componentsJoinedByString:@"_"]];
    }
    return [result array];
}

- (NSArray<NSString *> *)translate:(NSString *)baseString {
    id result = self.translationDict[[baseString.lowercaseString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    if ([result isKindOfClass:[NSString class]]) {
        return @[[Utilities applyFormatOfString:baseString toString:result]];
    }
    if ([result isKindOfClass:[NSArray class]]) {
        NSMutableArray *r = [NSMutableArray array];
        for (NSString *thisResult in (NSArray*)result) {
            [r addObject:[Utilities applyFormatOfString:baseString toString:thisResult]];
        }
        return r;
    }
    return nil;
}

@end
