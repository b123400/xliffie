//
//  TranslationUtility.m
//  Xliffie
//
//  Created by b123400 on 9/1/2016.
//  Copyright © 2016 b123400. All rights reserved.
//

#import "TranslationUtility.h"
#import <FGTranslator/FGTranslator.h>
#import <BRLocaleMap/BRLocaleMap.h>
#import "APIKeys.h"
#import <Crashlytics/Crashlytics.h>

@implementation TranslationUtility

+ (BOOL)isLocale:(NSString*)locale supportedForService:(BRLocaleMapService)service {
    return [BRLocaleMap locale:locale forService:service] != nil;
}

+ (void)translateTexts:(NSArray <NSString*> *)texts
          fromLanguage:(NSString*)sourceLocaleCode
            toLanguage:(NSString*)targetLocaleCode
           withService:(BRLocaleMapService)service
              callback:(void(^)(NSError*, NSArray <NSString*> *))callback {
    
    FGTranslator *translator = [self translatorWithService:service];
    
    NSString *sourceCode = [BRLocaleMap locale:sourceLocaleCode forService:service];
    NSString *targetCode = [BRLocaleMap locale:targetLocaleCode forService:service];
    
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
                                                                                , sourceLocaleCode]
                                                    }];
        callback(error, nil);
        return;
    }
    
    [translator translateTexts:texts
                    withSource:sourceCode
                        target:targetLocaleCode
                    completion:^(NSError *error, NSArray<NSString *> *translated, NSArray<NSString *> *sourceLanguage) {
                        callback(error, translated);
                        if (error) {
                            [[Crashlytics sharedInstance] recordError:error
                                               withAdditionalUserInfo:@{
                                                                        @"source": sourceLocaleCode,
                                                                        @"target": targetLocaleCode
                                                                        }];
                        }
                    }];
}

+ (FGTranslator*)translatorWithService:(BRLocaleMapService)service {
    FGTranslator *translator;
    switch (service) {
        case BRLocaleMapServiceMicrosoft:
            translator = [[FGTranslator alloc] initWithBingAzureClientId:MICROSOFT_TRANSLATE_CLIENT_ID
                                                                  secret:MICROSOFT_TRANSLATE_CLIENT_SECRET];
            break;
        
        case BRLocaleMapServiceGoogle:
            translator = [[FGTranslator alloc] initWithGoogleAPIKey:GOOGLE_TRANSLATE_API_KEY];
            // We need to to pretend to be sending from a browser
            translator.referer = GOOGLE_TRANSLATE_REFERER;
            
        default:
            break;
    }
    translator.preferSourceGuess = NO;
    return translator;
}

@end
