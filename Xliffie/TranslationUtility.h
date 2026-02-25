//
//  TranslationUtility.h
//  Xliffie
//
//  Created by b123400 on 9/1/2016.
//  Copyright © 2016 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TRANSLATION_ERROR_DOMAIN @"net.b123400.xliffie.translation.error"

typedef NS_ENUM(NSUInteger, XLFTranslationService) {
    XLFTranslationServiceMicrosoft = 0,
    XLFTranslationServiceGoogle    = 1,
    XLFTranslationServiceDeepl     = 2,
    XLFTranslationServiceNative    = 3,
};

@interface TranslationUtility : NSObject

+ (BOOL)isSourceLocale:(NSString*)locale supportedForService:(XLFTranslationService)service;
+ (BOOL)isTargetLocale:(NSString*)locale supportedForService:(XLFTranslationService)service;

+ (void)isSourceLocale:(NSString*)source
          targetLocale:(NSString*)target
   supportedForService:(XLFTranslationService)service
     completionHandler:(void(^)(BOOL))callback;

+ (void)needsDownloadForSourceLocale:(NSString *)source
                        targetLocale:(NSString *)target
                             service:(XLFTranslationService)service
                   completionHandler:(void(^)(BOOL))callback;

+ (void)translateTexts:(NSArray <NSString*> *)texts
          fromLanguage:(NSString*)sourceLocaleCode
            toLanguage:(NSString*)targetLocaleCode
           withService:(XLFTranslationService)service
             autoSplit:(BOOL)autoSplit
              callback:(void(^)(NSError*, NSArray <NSString*> *))callback;

@end
