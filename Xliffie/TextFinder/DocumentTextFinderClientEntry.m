//
//  DocumentTextFinderClientEntry.m
//  Xliffie
//
//  Created by b123400 on 2023/03/30.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "DocumentTextFinderClientEntry.h"

@implementation DocumentTextFinderClientEntry

- (NSString *)string {
    if (self.type == DocumentTextFinderClientEntryTypeSource) {
        return [self.pair plainSourceForDisplayWithModifier];
    }
    return self.pair.target;
}

- (NSAttributedString *)attributedString {
    if (self.type == DocumentTextFinderClientEntryTypeSource) {
        return [self.pair sourceForDisplayWithFormatSpecifierReplaced];
    }
    return [self.pair targetWithFormatSpecifierReplaced];
}

- (TranslationPair *)pair {
    if (!_pair) {
        return self.pairGroup.mainPair;
    }
    return _pair;
}

@end
