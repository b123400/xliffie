//
//  TranslationUtility.m
//  Xliffie
//
//  Created by b123400 on 9/1/2016.
//  Copyright © 2016 b123400. All rights reserved.
//

#import "TranslationUtility.h"
#import "Xliffie-Swift.h"
#import "APIKeys.h"

@implementation TranslationUtility

+ (BOOL)isSourceLocale:(NSString*)locale supportedForService:(XLFTranslationService)service {
    return [LocaleMap sourceLocale:locale forService:service] != nil;
}

+ (BOOL)isTargetLocale:(NSString*)locale supportedForService:(XLFTranslationService)service {
    return [LocaleMap targetLocale:locale forService:service] != nil;
}

+ (void)isSourceLocale:(NSString*)source
          targetLocale:(NSString*)target
   supportedForService:(XLFTranslationService)service
     completionHandler:(void(^)(BOOL))callback {
    return [LocaleMap isTranslationPairSupportedWithSource:source target:target for:service completionHandler:callback];
}

+ (void)needsDownloadForSourceLocale:(NSString *)source
                        targetLocale:(NSString *)target
                             service:(XLFTranslationService)service
                   completionHandler:(void(^)(BOOL))callback {
    [LocaleMap doesTranslationPairNeedsDownloadWithSource:source target:target for:service completionHandler:callback];
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

    NSString *sourceCode = [LocaleMap sourceLocale:sourceLocaleCode forService:service];
    NSString *targetCode = [LocaleMap targetLocale:targetLocaleCode forService:service];

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
                            cached:YES
                 completionHandler:^(NSArray<NSString *> * _Nullable translated, NSError * _Nullable error) {
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
