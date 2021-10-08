//
//  MatomoTracker+Shared.h
//  Xliffie
//
//  Created by b123400 on 2021/10/01.
//  Copyright © 2021 b123400. All rights reserved.
//

@import MatomoTracker;

NS_ASSUME_NONNULL_BEGIN

@interface MatomoTracker (Shared)

+ (MatomoTracker*)shared;
- (void)trackWithIsolatedEventWithCategory:(NSString *)category
                                    action:(NSString *)action
                                      name:(NSString * _Nullable)name
                                       url:(NSURL * _Nullable)url;

- (void)trackWithIsolatedEventWithCategory:(NSString *)category
                                    action:(NSString *)action
                                    number:(NSNumber * _Nullable)number
                                       url:(NSURL * _Nullable)url;

- (void)trackWithIsolatedEventWithCategory:(NSString *)category
                                    action:(NSString *)action
                                      name:(NSString * _Nullable)name
                                    number:(NSNumber * _Nullable)number
                                       url:(NSURL * _Nullable)url;

@end

NS_ASSUME_NONNULL_END
