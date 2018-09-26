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
             autoSplit:(BOOL)autoSplit
              callback:(void(^)(NSError*, NSArray <NSString*> *))callback {
    
    NSMutableArray *allTexts = [NSMutableArray arrayWithArray:texts];
    NSMutableArray <NSArray<NSString*>*> *chunks = [NSMutableArray array];
    while (allTexts.count) {
        NSUInteger chunkTextLength = 0;
        NSMutableArray *thisChunkTexts = [NSMutableArray array];
        while (allTexts.count) {
            NSString *thisText = allTexts[0];
            NSUInteger lengthIfAdded = chunkTextLength + thisText.length;
            if (service == BRLocaleMapServiceMicrosoft) {
                if (lengthIfAdded >= 10000 && thisChunkTexts.count) {
                    // If there is a single entry that has > 10000 char, just let it pass
                    break;
                }
            }
            [thisChunkTexts addObject:thisText];
            lengthIfAdded += thisText.length;
            [allTexts removeObjectAtIndex:0];
            if (service == BRLocaleMapServiceMicrosoft) {
                if (thisChunkTexts.count >= 2000) {
                    break;
                }
            } else if (service == BRLocaleMapServiceGoogle) {
                if (thisChunkTexts.count >= 128) {
                    break;
                }
            }
        }
        [chunks addObject:thisChunkTexts];
    }

    NSMutableArray *errors = [NSMutableArray arrayWithCapacity:chunks.count];
    NSMutableArray *translatedChunks = [NSMutableArray arrayWithCapacity:chunks.count];
    NSLock *errorArrayLock = [[NSLock alloc] init];
    dispatch_group_t group = dispatch_group_create();
    for (NSArray <NSString*> *thisTexts in chunks) {
        NSMutableArray *thisChunk = [NSMutableArray array];
        [translatedChunks addObject:thisChunk];
        dispatch_group_enter(group);
        [self translateTexts:thisTexts
                fromLanguage:sourceLocaleCode
                  toLanguage:targetLocaleCode
                 withService:service
                    callback:^(NSError *error, NSArray<NSString *> *results) {
                        [thisChunk addObjectsFromArray:results];
                        if (error) {
                            [errorArrayLock lock];
                            [errors addObject:error];
                            [errorArrayLock unlock];
                        }
                        dispatch_group_leave(group);
                    }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (errors.count) {
            NSString *jointErrorString = [[errors valueForKey:@"localizedDescription"] componentsJoinedByString:@"\n"];
            NSError *error = [NSError errorWithDomain:TRANSLATION_ERROR_DOMAIN
                                                 code:0
                                             userInfo:@{NSLocalizedDescriptionKey:
                                                            [NSString stringWithFormat:NSLocalizedString(@"Errors during translation:\n%@", nil), jointErrorString]}];
            callback(error, nil);
            return;
        }
        NSArray <NSString*> *flattenedArray = [translatedChunks valueForKeyPath: @"@unionOfArrays.self"];
        callback(nil, flattenedArray);
    });
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

    [translator chunkedTranslateTexts:texts
                           withSource:sourceCode
                               target:targetLocaleCode
                           completion:^(NSError *error, NSArray<NSString *> *translated) {
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
            translator = [[FGTranslator alloc] initWithAzureAPIKey:MICROSOFT_TRANSLATE_API_KEY];
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
