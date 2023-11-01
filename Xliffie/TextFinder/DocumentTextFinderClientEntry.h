//
//  DocumentTextFinderClientEntry.h
//  Xliffie
//
//  Created by b123400 on 2023/03/30.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TranslationPair.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    DocumentTextFinderClientEntryTypeSource,
    DocumentTextFinderClientEntryTypeTarget,
} DocumentTextFinderClientEntryType;

@interface DocumentTextFinderClientEntry : NSObject

@property (assign, nonatomic) DocumentTextFinderClientEntryType type;
@property (strong, nonatomic) TranslationPair *pair;
@property (assign, nonatomic) NSRange range;

- (NSString *)string;
- (NSAttributedString *)attributedString;

@end

NS_ASSUME_NONNULL_END
