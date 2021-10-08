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

- (void)trackWithIsolatedEventWithCategory:(NSString *)category
                                    action:(NSString *)action
                                      name:(NSString *)name
                                       url:(NSURL *)url {
    [self trackWithIsolatedEventWithCategory:category
                                      action:action
                                        name:name
                                      number:nil
                                         url:url];
}

- (void)trackWithIsolatedEventWithCategory:(NSString *)category
                                    action:(NSString *)action
                                    number:(NSNumber * _Nullable)number
                                       url:(NSURL * _Nullable)url {
    [self trackWithIsolatedEventWithCategory:category
                                      action:action
                                        name:number.stringValue
                                      number:number
                                         url:url];
}
- (void)trackWithIsolatedEventWithCategory:(NSString *)category
                                    action:(NSString *)action
                                      name:(NSString *)name
                                    number:(NSNumber *)number
                                       url:(NSURL *)url {
    [self startNewSession];
    [self trackWithEventWithCategory:category
                              action:action
                                name:name
                              number:number
                                 url:url];
}

@end
