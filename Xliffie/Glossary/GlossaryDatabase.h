//
//  GlossaryDatabase.h
//  Xliffie
//
//  Created by b123400 on 2023/07/12.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    GlossaryPlatformMac,
    GlossaryPlatformIOS,
} GlossaryPlatform;

@interface GlossaryDatabase : NSObject

@property (nonatomic, assign) GlossaryPlatform platform;
@property (nonatomic, strong) NSString *locale;

+ (NSArray<GlossaryDatabase*> *)downloadedDatabasesWithPlatform:(GlossaryPlatform)platform;
+ (NSArray<NSString*>*)localesWithPlatform:(GlossaryPlatform)platform;

- (instancetype)initWithPlatform:(GlossaryPlatform)platform locale:(NSString *)locale;

- (NSURL *)databaseURL;
- (NSString *)databasePath;
- (BOOL)isDownloaded;
- (unsigned long long)fileSize;

- (NSURLSessionDownloadTask *)downloadTask;
- (NSProgress *)download:(void (^)(NSError *error))callback;
- (void)cancelDownload;

- (void)deleteDatabase;

- (BOOL)open;
- (NSArray *)findTargetsWithSource:(NSString *)source;
- (NSArray *)findRowsWithTarget:(NSString *)target;
- (NSArray *)findTargetsWithSource:(NSString *)source andBundlePath:(NSString *)bundlePath;

@end

NS_ASSUME_NONNULL_END
