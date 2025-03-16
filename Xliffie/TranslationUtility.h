//
//  TranslationUtility.h
//  Xliffie
//
//  Created by b123400 on 9/1/2016.
//  Copyright © 2016 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BRLocaleMap/BRLocaleMap.h>

#define TRANSLATION_ERROR_DOMAIN @"net.b123400.xliffie.translation.error"

@interface TranslationUtility : NSObject

+ (BOOL)isSourceLocale:(NSString*)locale supportedForService:(BRLocaleMapService)service;
+ (BOOL)isTargetLocale:(NSString*)locale supportedForService:(BRLocaleMapService)service;

+ (void)translateTexts:(NSArray <NSString*> *)texts
          fromLanguage:(NSString*)sourceLocaleCode
            toLanguage:(NSString*)targetLocaleCode
           withService:(BRLocaleMapService)service
             autoSplit:(BOOL)autoSplit
              callback:(void(^)(NSError*, NSArray <NSString*> *))callback;

@end
