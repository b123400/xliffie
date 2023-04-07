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
        return self.pair.source;
    }
    return self.pair.target;
}

@end