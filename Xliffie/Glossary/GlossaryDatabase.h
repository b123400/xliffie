//
//  GlossaryDatabase.h
//  Xliffie
//
//  Created by b123400 on 2023/07/12.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GlossarySearchRow.h"
#import "GlossarySearchResults.h"

#define GLOSSARY_DATABASE_DOWNLOADED_NOTIFICATION @"GLOSSARY_DATABASE_DOWNLOADED_NOTIFICATION"
#define GLOSSARY_DATABASE_DELETED_NOTIFICATION @"GLOSSARY_DATABASE_DELETED_NOTIFICATION"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    GlossaryPlatformAny,
    GlossaryPlatformMac,
    GlossaryPlatformIOS,
} GlossaryPlatform;

@interface GlossaryDatabase : NSObject

@property (nonatomic, assign) GlossaryPlatform platform;
@property (nonatomic, strong) NSString *locale;

+ (NSArray<GlossaryDatabase*> *)downloadedDatabasesWithPlatform:(GlossaryPlatform)platform;
+ (NSArray<NSString*>*)localesWithPlatform:(GlossaryPlatform)platform;
+ (GlossaryDatabase *)databaseWithPlatform:(GlossaryPlatform)platform locale:(NSString *)locale;

+ (NSArray<NSString*>*)recommendedRelatedDatabaseForLocale:(NSString *)locale withPlatform:(GlossaryPlatform)platform;
+ (NSArray<NSString*> *)relatedDatabaseForLocale:(NSString *)locale withPlatform:(GlossaryPlatform)platform;

+ (void)searchGlossariesForTerms:(NSArray<NSString *> *)terms
                    withPlatform:(GlossaryPlatform)platform
                      fromLocale:(NSString *)sourceLocale
                        toLocale:(NSString *)targetLocale
                        callback:(void(^)(GlossarySearchResults *results))callback;

- (NSURL *)databaseURL;
- (NSString *)databasePath;
- (BOOL)isDownloaded;
- (BOOL)testDatabase;
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
