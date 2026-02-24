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

+ (BOOL)isSourceLocale:(NSString*)locale supportedForService:(XLFTranslationService)service {
    if (service == XLFTranslationServiceNative) {
        return YES;
    }
    return [BRLocaleMap sourceLocale:locale forService:(BRLocaleMapService)service] != nil;
}

+ (BOOL)isTargetLocale:(NSString*)locale supportedForService:(XLFTranslationService)service {
    if (service == XLFTranslationServiceNative) {
        return YES;
    }
    return [BRLocaleMap targetLocale:locale forService:(BRLocaleMapService)service] != nil;
}

+ (void)translateTexts:(NSArray <NSString*> *)texts
          fromLanguage:(NSString*)sourceLocaleCode
            toLanguage:(NSString*)targetLocaleCode
           withService:(XLFTranslationService)service
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
           withService:(XLFTranslationService)service
              callback:(void(^)(NSError*, NSArray <NSString*> *))callback {

    Translator *translator = [self translatorWithService:service];

    NSString *sourceCode;
    NSString *targetCode;

    if (service == XLFTranslationServiceNative) {
        // NativeTranslator uses locale identifiers directly, no BRLocaleMap lookup needed
        sourceCode = sourceLocaleCode;
        targetCode = targetLocaleCode;
    } else {
        sourceCode = [BRLocaleMap sourceLocale:sourceLocaleCode forService:(BRLocaleMapService)service];
        targetCode = [BRLocaleMap targetLocale:targetLocaleCode forService:(BRLocaleMapService)service];
    }

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

+ (Translator*)translatorWithService:(XLFTranslationService)service {
    Translator *translator;
    switch (service) {
        case XLFTranslationServiceMicrosoft:
            translator = [[BingTranslator alloc] initWithApiKey:MICROSOFT_TRANSLATE_API_KEY];
            break;

        case XLFTranslationServiceGoogle: {
            GoogleTranslator *googleTranslator = [[GoogleTranslator alloc] initWithApiKey:GOOGLE_TRANSLATE_API_KEY referer:GOOGLE_TRANSLATE_REFERER];
            translator = googleTranslator;
            break;
        }

        case XLFTranslationServiceDeepl:
            translator = [[DeeplTranslator alloc] initWithApiKey:DEEPL_TRANSLATE_API_KEY];
            break;

        case XLFTranslationServiceNative:
            if (@available(macOS 26.0, *)) {
                translator = [[NativeTranslator alloc] init];
            }
            break;
    }
    return translator;
}

@end
