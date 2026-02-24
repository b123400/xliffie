//
//  TranslationWindowController.h
//  Xliffie
//
//  Created by b123400 on 13/1/2016.
//  Copyright © 2016 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TranslationPair.h"
#import "TranslationUtility.h"

@interface TranslationWindowController : NSWindowController

- (instancetype)initWithTranslationPairs:(NSArray <TranslationPair*> *)pairs
                      translationService:(XLFTranslationService)service;


@end
