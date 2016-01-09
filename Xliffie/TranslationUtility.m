//
//  TranslationUtility.m
//  Xliffie
//
//  Created by b123400 on 9/1/2016.
//  Copyright © 2016 b123400. All rights reserved.
//

#import "TranslationUtility.h"
#import <FGTranslator/FGTranslator.h>
#import "APIKeys.h"

@implementation TranslationUtility

+ (void)translateTexts:(NSArray <NSString*> *)texts
          fromLanguage:(NSString*)sourceLocaleCode
            toLanguage:(NSString*)targetLocaleCode
           withService:(TranslationService)service
              callback:(void(^)(NSError*, NSArray <NSString*> *))callback {
    
    FGTranslator *translator = [self translatorWithService:service];
    
    [translator translateTexts:texts
                    withSource:[self languageCode:sourceLocaleCode forService:service]
                        target:[self languageCode:targetLocaleCode forService:service]
                    completion:^(NSError *error, NSArray<NSString *> *translated, NSArray<NSString *> *sourceLanguage) {
                        callback(error, translated);
                    }];
}

+ (FGTranslator*)translatorWithService:(TranslationService)service {
    FGTranslator *translator;
    switch (service) {
        case TranslationServiceBing:
            translator = [[FGTranslator alloc] initWithBingAzureClientId:MICROSOFT_TRANSLATE_CLIENT_ID
                                                                  secret:MICROSOFT_TRANSLATE_CLIENT_SECRET];
            break;
        
        case TranslationServiceGoogle:
            translator = [[FGTranslator alloc] initWithGoogleAPIKey:GOOGLE_TRANSLATE_API_KEY];
            // We need to to pretend to be sending from a browser
            translator.referer = GOOGLE_TRANSLATE_REFERER;
            
        default:
            break;
    }
    translator.preferSourceGuess = NO;
    return translator;
}

#pragma mark - Language codes

+ (NSString*)languageCode:(NSString*)language forService:(TranslationService)service {
    switch (service) {
        case TranslationServiceBing:
            return [self languageCodeForBing:language];
            break;
        
        case TranslationServiceGoogle:
            return [self languageCodeForGoogle:language];
        default:
            break;
    }
    return nil;
}

+ (NSString*)languageCodeForGoogle:(NSString*)languageCode {
    // https://cloud.google.com/translate/v2/using_rest#language-params
    return languageCode;
}

+ (NSString*)languageCodeForBing:(NSString*)languageCode {
    // https://msdn.microsoft.com/en-us/library/hh456380.aspx
    return languageCode;
}

@end
