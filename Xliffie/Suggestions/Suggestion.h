//
//  Suggestion.h
//  Xliffie
//
//  Created by b123400 on 2022/12/06.
//  Copyright © 2022 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "File.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    SuggestionSourceGlossary = 0,
    SuggestionSourceFile = 1,
    SuggestionSourceAppleGlossary = 2,
    SuggestionSourceCustomGlossary = 3,
} SuggestionSource;

@interface Suggestion : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) SuggestionSource source;
@property (nonatomic, strong) File *sourceFile;
@property (nonatomic, assign) NSInteger appleGlossaryHitCount;

- (NSAttributedString *)stringForDisplay;

@end

NS_ASSUME_NONNULL_END
