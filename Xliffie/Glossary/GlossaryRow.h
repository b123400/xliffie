//
//  GlossaryRow.h
//  Xliffie
//
//  Created by b123400 on 2021/09/28.
//  Copyright © 2021 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TranslationPair.h"

NS_ASSUME_NONNULL_BEGIN

@interface GlossaryRow : NSObject

@property (nonatomic, strong) TranslationPair *translationPair;
@property (nonatomic, strong) NSString *glossary;
@property (nonatomic, assign) BOOL shouldApply;

@end

NS_ASSUME_NONNULL_END
