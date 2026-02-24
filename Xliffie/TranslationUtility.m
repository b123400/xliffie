//
//  TranslationUtility.m
//  Xliffie
//
//  Created by b123400 on 9/1/2016.
//  Copyright © 2016 b123400. All rights reserved.
//

#import "TranslationUtility.h"
#import "Xliffie-Swift.h"
#import <BRLocaleMap/BRLocaleMap.h>
#import "APIKeys.h"

@implementation TranslationUtility

+ (BOOL)isSourceLocale:(NSString*)locale supportedForService:(BRLocaleMapService)service {
    return [BRLocaleMap sourceLocale:locale forService:service] != nil;
}

+ (BOOL)isTargetLocale:(NSString*)locale supportedForService:(BRLocaleMapService)service {
    return [BRLocaleMap targetLocale:locale forService:service] != nil;
}

+ (void)translateTexts:(NSArray <NSString*> *)texts
          fromLanguage:(NSString*)sourceLocaleCode
            toLanguage:(NSString*)targetLocaleCode
           withService:(BRLocaleMapService)service
             autoSplit:(BOOL)autoSplit
              callback:(void(^)(NSError*, NSArray <NSString*> *))callback {
    
    // The new Swift Translator classes handle batching and splitting automatically,
    // so we can simply delegate to the main translation method
    [self translateTexts:texts
            fromLanguage:sourceLocaleCode
              toLanguage:targetLocaleCode
             withService:service
                callback:callback];
}

+ (void)translateTexts:(NSArray <NSString*> *)texts
          fromLanguage:(NSString*)sourceLocaleCode
            toLanguage:(NSString*)targetLocaleCode
           withService:(BRLocaleMapService)service
              callback:(void(^)(NSError*, NSArray <NSString*> *))callback {

    Translator *translator = [self translatorWithService:service];

    NSString *sourceCode = [BRLocaleMap sourceLocale:sourceLocaleCode forService:service];
    NSString *targetCode = [BRLocaleMap targetLocale:targetLocaleCode forService:service];

    if (!sourceCode) {
        NSError *error = [NSError errorWithDomain:TRANSLATION_ERROR_DOMAIN
                                             code:0
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey: [NSString stringWithFormat:
                                                                                NSLocalizedString(@"Cannot translate from %@",
                                                                                                  @"Translation source not found")
                                                                                , sourceLocaleCode]
                                                    }];
        callback(error, nil);
        return;
    }

    if (!targetCode) {
        NSError *error = [NSError errorWithDomain:TRANSLATION_ERROR_DOMAIN
                                             code:0
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey: [NSString stringWithFormat:
                                                                                NSLocalizedString(@"Cannot translate to %@",
                                                                                                  @"Translation target not found")
                                                                                , targetLocaleCode]
                                                    }];
        callback(error, nil);
        return;
    }

    // Use the new Swift Translator API which handles batching internally
    [translator translateWithTexts:texts
                      sourceLocale:sourceCode
                      targetLocale:targetCode
                        completion:^(NSError *error, NSArray<NSString *> *translated) {
                            callback(error, translated);
                        }];
}

+ (Translator*)translatorWithService:(BRLocaleMapService)service {
    Translator *translator;
    switch (service) {
        case BRLocaleMapServiceMicrosoft:
            translator = [[BingTranslator alloc] initWithApiKey:MICROSOFT_TRANSLATE_API_KEY];
            break;

        case BRLocaleMapServiceGoogle: {
            GoogleTranslator *googleTranslator = [[GoogleTranslator alloc] initWithApiKey:GOOGLE_TRANSLATE_API_KEY referer:GOOGLE_TRANSLATE_REFERER];
            translator = googleTranslator;
            break;
        }

        case BRLocaleMapServiceDeepl:
            translator = [[DeeplTranslator alloc] initWithApiKey:DEEPL_TRANSLATE_API_KEY];
            break;
    }
    return translator;
}

@end
