//
//  Glossary.m
//  Xliffie
//
//  Created by b123400 on 2021/09/27.
//  Copyright © 2021 b123400. All rights reserved.
//

#import "Glossary.h"

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
        @"ar", @"ca", @"cs", @"da", @"de", @"el", @"en-au", @"en-gb", @"es-419",
        @"es", @"fi", @"fr-ca", @"fr", @"he", @"hi", @"hr", @"hu", @"id", @"it",
        @"ja", @"ko", @"ms", @"nl", @"no", @"pl", @"pt-br", @"pt-pt", @"ro", @"ru",
        @"sk", @"sv", @"th", @"tr", @"uk", @"vi", @"zh-cn", @"zh-hk", @"zh-tw",
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
            return @"zh-hk";
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
    [result addObject:[components componentsJoinedByString:@"-"]];
    if (components.count >= 2) {
        [result addObject:[NSString stringWithFormat:@"%@-%@", components.firstObject, components.lastObject]];
    }
    for (NSInteger i = components.count; i >= 1; i--) {
        [result addObject:[[components subarrayWithRange:NSMakeRange(0, i)] componentsJoinedByString:@"-"]];
    }
    return [result array];
}

- (NSString *)translate:(NSString *)baseString isMenu:(BOOL)isMenu {
    NSDictionary<NSString *, NSArray<NSString *>*> *transDict = self.translationDict[baseString.lowercaseString];
    if (transDict.count == 0) {
        return nil;
    }
    if (transDict.count == 1) {
        return [transDict allKeys].firstObject;
    }
    for (NSString *tran in transDict) {
        NSArray *positions = transDict[tran];
        BOOL isTranBelongsToMenu = [[positions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self CONTAINS[cd] 'menu'"]] count] > 0;
        if (isTranBelongsToMenu && isMenu) {
            return tran;
        }
        if (!isTranBelongsToMenu && !isMenu) {
            return tran;
        }
    }
    return [transDict allKeys].firstObject;
}

@end
