//
//  MatomoTracker+Shared.m
//  Xliffie
//
//  Created by b123400 on 2021/10/01.
//  Copyright © 2021 b123400. All rights reserved.
//

#import "MatomoTracker+Shared.h"

@implementation MatomoTracker (Shared)

+ (MatomoTracker*)shared {
    static MatomoTracker* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MatomoTracker alloc] initWithSiteId:@"1"
                                                       baseURL:[NSURL URLWithString:@"https://matomo.b123400.net/matomo.php"]
                                                     userAgent:nil];
    });
    return sharedInstance;
}

@end
