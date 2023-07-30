//
//  GlossaryDatabase.m
//  Xliffie
//
//  Created by b123400 on 2023/07/12.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "GlossaryDatabase.h"
#import <sqlite3.h>

@interface GlossaryDatabase ()

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

@end

@implementation GlossaryDatabase {
    sqlite3 *_sqlite;
}

+ (NSArray<NSString*>*)databasesWithPlatform:(GlossaryPlatform)platform {
    if (platform == GlossaryPlatformMac) {
        return @[
            @"Base",
            @"Dutch",
            @"English",
            @"French",
            @"German",
            @"Italian",
            @"Japanese",
            @"Spanish",
            @"ar",
            @"ca",
            @"cs",
            @"da",
            @"de",
            @"el",
            @"en",
            @"en_AU",
            @"en_CA",
            @"en_GB",
            @"en-GB",
            @"en_IN",
            @"es",
            @"es_419",
            @"es_MX",
            @"fi",
            @"fr",
            @"fr-CA",
            @"fr_CA",
            @"he",
            @"hi",
            @"hi_Latn",
            @"hr",
            @"hu",
            @"id",
            @"it",
            @"ja",
            @"ko",
            @"ms",
            @"nb",
            @"nl",
            @"no",
            @"pl",
            @"pt-PT",
            @"pt",
            @"pt_BR",
            @"pt_PT",
            @"ro",
            @"ru",
            @"sk",
            @"sv",
            @"ta",
            @"th",
            @"tr",
            @"uk",
            @"vi",
            @"yue_CN",
            @"zh-Hans",
            @"zh-Hant",
            @"zh_CN",
            @"zh_HK",
            @"zh_TW",
        ];
    } else if (platform == GlossaryPlatformIOS) {
        return @[
            @"Base",
            @"Dutch",
            @"English",
            @"French",
            @"German",
            @"Italian",
            @"Japanese",
            @"Spanish",
            @"ar",
            @"ar_AE",
            @"ar_SA",
            @"bn_Latn",
            @"ca",
            @"cs",
            @"da",
            @"de",
            @"de_AT",
            @"de_CH",
            @"el",
            @"en",
            @"en_AU",
            @"en_CA",
            @"en_GB",
            @"en_ID",
            @"en_IN",
            @"en_MY",
            @"en_NZ",
            @"en_SG",
            @"es",
            @"es_419",
            @"es_AR",
            @"es_CL",
            @"es_CO",
            @"es_CR",
            @"es_GT",
            @"es_MX",
            @"es_PA",
            @"es_PE",
            @"fi",
            @"fr",
            @"fr_BE",
            @"fr_CA",
            @"fr_CH",
            @"gu_Latn",
            @"he",
            @"hi",
            @"hi_Latn",
            @"hr",
            @"hu",
            @"id",
            @"it",
            @"it_CH",
            @"ja",
            @"kn_Latn",
            @"ko",
            @"ml_Latn",
            @"mr_Latn",
            @"ms",
            @"nl",
            @"no",
            @"or_Latn",
            @"pa_Latn",
            @"pl",
            @"pt",
            @"pt_BR",
            @"pt_PT",
            @"ro",
            @"ru",
            @"sk",
            @"sv",
            @"ta_Latn",
            @"te_Latn",
            @"th",
            @"tr",
            @"uk",
            @"vi",
            @"yue_CN",
            @"zh_CN",
            @"zh_HK",
            @"zh_TW",
        ];
    }
    return nil;
}

+ (NSArray<NSString*>*)recommendedRelatedDatabaseForLocale:(NSString *)locale withPlatform:(GlossaryPlatform)platform {
    NSArray *groups = nil;
    if (platform == GlossaryPlatformMac) {
        groups = @[
            @[@"nl", @"Dutch",],
            @[@"en", @"English",],
            @[@"fr", @"French",],
            @[@"de", @"German",],
            @[@"it", @"Italian",],
            @[@"ja", @"Japanese",],
            @[@"es", @"Spanish",],
            @[@"zh_HK", @"zh-Hant"],
            @[@"zh_TW", @"zh-Hant"],
            @[@"zh_CN", @"zh-Hans", @"yue_CN"],
        ];
    } else if (platform == GlossaryPlatformIOS) {
        groups = @[
            @[@"nl", @"Dutch",],
            @[@"en", @"English"],
            @[@"fr", @"French"],
            @[@"de", @"German"],
            @[@"it", @"Italian"],
            @[@"ja", @"Japanese"],
            @[@"es", @"Spanish"],
            @[@"zh_CN", @"yue_CN"],
        ];
    }
    for (NSArray *group in groups) {
        if ([group containsObject:locale]) {
            return [group filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self != %@", locale]];
        }
    }
    return nil;
}

+ (NSArray<NSString*> *)relatedDatabaseForLocale:(NSString *)locale withPlatform:(GlossaryPlatform)platform {
    NSArray<NSString*> *dbs = [GlossaryDatabase databasesWithPlatform:platform];
    NSMutableArray *result = [NSMutableArray array];
    NSMutableArray *parts = [[locale componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-_"]] mutableCopy];
    while ([parts count]) {
        NSString *joined = [parts componentsJoinedByString:@"."];
        for (NSString *db in dbs) {
            NSString *replaced = [db stringByReplacingOccurrencesOfString:@"_" withString:@"."];
            replaced = [replaced stringByReplacingOccurrencesOfString:@"-" withString:@"."];
            if ([replaced hasPrefix:joined]) {
                [result addObject:db];
            }
        }
        [parts removeLastObject];
    }
    return result;
}

+ (NSString *)fileSizeForLocale:(NSString *)locale withPlatform:(GlossaryPlatform)platform {
    if (platform == GlossaryPlatformMac) {
        NSDictionary *dict = @{
            @"Base": @"32K",
            @"Dutch": @"200K",
            @"English": @"1M",
            @"French": @"204K",
            @"German": @"204K",
            @"Italian": @"200K",
            @"Japanese": @"212K",
            @"Spanish": @"200K",
            @"ar": @"41M",
            @"ca": @"38M",
            @"cs": @"37M",
            @"da": @"37M",
            @"de": @"38M",
            @"el": @"45M",
            @"en-GB": @"24K",
            @"en": @"31M",
            @"en_AU": @"36M",
            @"en_CA": @"120K",
            @"en_GB": @"36M",
            @"en_IN": @"120K",
            @"es": @"37M",
            @"es_419": @"37M",
            @"es_MX": @"212K",
            @"fi": @"37M",
            @"fr-CA": @"28K",
            @"fr": @"38M",
            @"fr_CA": @"38M",
            @"he": @"40M",
            @"hi": @"48M",
            @"hi_Latn": @"464K",
            @"hr": @"37M",
            @"hu": @"38M",
            @"id": @"37M",
            @"it": @"37M",
            @"ja": @"39M",
            @"ko": @"38M",
            @"ms": @"37M",
            @"nb": @"28K",
            @"nl": @"37M",
            @"no": @"36M",
            @"pl": @"37M",
            @"pt-PT": @"28K",
            @"pt": @"23M",
            @"pt_BR": @"15M",
            @"pt_PT": @"37M",
            @"ro": @"38M",
            @"ru": @"44M",
            @"sk": @"38M",
            @"sv": @"37M",
            @"ta": @"12K",
            @"th": @"48M",
            @"tr": @"37M",
            @"uk": @"43M",
            @"vi": @"39M",
            @"yue_CN": @"6M",
            @"zh-Hans": @"24K",
            @"zh-Hant": @"24K",
            @"zh_CN": @"36M",
            @"zh_HK": @"35M",
            @"zh_TW": @"36M",
        };
        return dict[locale];
    } else if (GlossaryPlatformIOS) {
        NSDictionary *dict = @{
            @"Base": @"12K",
            @"Dutch": @"96K",
            @"English": @"92K",
            @"French": @"96K",
            @"German": @"96K",
            @"Italian": @"96K",
            @"Japanese": @"104K",
            @"Spanish": @"96K",
            @"ar": @"18M",
            @"ar_AE": @"12K",
            @"ar_SA": @"12K",
            @"bn_Latn": @"48K",
            @"ca": @"17M",
            @"cs": @"17M",
            @"da": @"16M",
            @"de": @"17M",
            @"de_AT": @"12K",
            @"de_CH": @"12K",
            @"el": @"20M",
            @"en": @"17M",
            @"en_AU": @"16M",
            @"en_CA": @"120K",
            @"en_GB": @"16M",
            @"en_ID": @"12K",
            @"en_IN": @"192K",
            @"en_MY": @"12K",
            @"en_NZ": @"12K",
            @"en_SG": @"12K",
            @"es": @"16M",
            @"es_419": @"16M",
            @"es_AR": @"12K",
            @"es_CL": @"12K",
            @"es_CO": @"12K",
            @"es_CR": @"12K",
            @"es_GT": @"12K",
            @"es_MX": @"12K",
            @"es_PA": @"12K",
            @"es_PE": @"12K",
            @"fi": @"16M",
            @"fr": @"17M",
            @"fr_BE": @"12K",
            @"fr_CA": @"17M",
            @"fr_CH": @"12K",
            @"gu_Latn": @"48K",
            @"he": @"17M",
            @"hi": @"21M",
            @"hi_Latn": @"496K",
            @"hr": @"16M",
            @"hu": @"17M",
            @"id": @"16M",
            @"it": @"16M",
            @"it_CH": @"12K",
            @"ja": @"17M",
            @"kn_Latn": @"48K",
            @"ko": @"17M",
            @"ml_Latn": @"52K",
            @"mr_Latn": @"48K",
            @"ms": @"16M",
            @"nl": @"16M",
            @"no": @"16M",
            @"or_Latn": @"48K",
            @"pa_Latn": @"48K",
            @"pl": @"16M",
            @"pt": @"9.5M",
            @"pt_BR": @"6.9M",
            @"pt_PT": @"16M",
            @"ro": @"17M",
            @"ru": @"20M",
            @"sk": @"17M",
            @"sv": @"16M",
            @"ta_Latn": @"52K",
            @"te_Latn": @"48K",
            @"th": @"21M",
            @"tr": @"16M",
            @"uk": @"19M",
            @"vi": @"17M",
            @"yue_CN": @"988K",
            @"zh_CN": @"16M",
            @"zh_HK": @"16M",
            @"zh_TW": @"16M",
        };
        return dict[locale];
    }
    return nil;
}

- (instancetype)initWithPlatform:(GlossaryPlatform)platform locale:(NSString *)locale {
    if (self = [super init]) {
        self.platform = platform;
        self.locale = locale;
    }
    return self;
}

- (void)dealloc {
    if (_sqlite) {
        sqlite3_close_v2(_sqlite);
    }
}

- (NSURL *)databaseURL {
    NSString *platform = self.platform == GlossaryPlatformMac ? @"macos" : @"ios";
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://b123400.net/xliffie/glossary/%@/%@.db", platform, self.locale]];
}

- (NSString *)databasePath {
    NSString *platform = self.platform == GlossaryPlatformMac ? @"macos" : @"ios";
    NSArray<NSURL *> *documentPaths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSString *docPath = [[documentPaths lastObject] path];
    NSString *dbPath = [[[docPath stringByAppendingPathComponent:@"glossary"]
                         stringByAppendingPathComponent:platform]
                        stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.db", self.locale]];
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:[dbPath stringByDeletingLastPathComponent]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if (error) {
        NSLog(@"Cannot create directory %@ %@", dbPath, error);
    }
    return dbPath;
}

- (NSProgress *)download:(void (^)(NSError *error))callback {
    if ([self isDownloaded]) {
        // or delete and re-download?
        return nil;
    }
    if (self.downloadTask) {
        if (@available(macOS 10.13, *)) {
            return self.downloadTask.progress;
        }
        return nil;
    }
    __weak typeof(self) _self = self;
    NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithURL:self.databaseURL
                                    completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            callback(error);
            return;
        }
        NSError *err = nil;
        [[NSFileManager defaultManager] copyItemAtURL:location
                                                toURL:[NSURL fileURLWithPath:_self.databasePath]
                                                error:&err];
        if (err) {
            callback(err);
            return;
        }
        _self.downloadTask = nil;
        callback(nil);
    }];
    self.downloadTask = task;
    [task resume];
    if (@available(macOS 10.13, *)) {
        return task.progress;
    }
    return nil;
}

- (void)cancelDownload {
    [self.downloadTask cancel];
    self.downloadTask = nil;
}

- (BOOL)isDownloaded {
    return [[NSFileManager defaultManager] fileExistsAtPath:self.databasePath];
}

- (BOOL)open {
    if (!self.isDownloaded) return NO;
    if (_sqlite) return YES;

    sqlite3 *dbConnection = nil;
    int rc = sqlite3_open_v2([self.databasePath UTF8String], &dbConnection, SQLITE_OPEN_READONLY, NULL);
    if (rc != SQLITE_OK) {
        return NO;
    }
    _sqlite = dbConnection;
    return YES;
}

- (void)findRowsWithTarget:(NSString *)target {
    [self query:@"SELECT source, target, bundle_path FROM translations WHERE target = ?" withParams:@[target]];
}

- (void)findTargetsWithSource:(NSString *)source andBundlePath:(NSString *)bundlePath {
    [self query:@"SELECT target FROM translations WHERE source = ? AND bundle_path = ?" withParams:@[source, bundlePath]];
}

- (NSArray *)query:(NSString *)sql withParams:(NSArray * _Nullable)params {
    sqlite3_stmt *compiledStatement = nil;
    int rc = 0;
    if ((rc = sqlite3_prepare_v2(_sqlite, [sql UTF8String], -1, &compiledStatement, nil)) != SQLITE_OK) {
        NSLog(@"Cannot prepare sql (%d) : %@", rc, sql);
        return nil;
    }
    if (params) {
        for (int i = 0; i < params.count; i++) {
            id param = params[i];
            if ([param isKindOfClass:[NSString class]]) {
                sqlite3_bind_text(compiledStatement, i + 1, [(NSString*)param UTF8String], -1, SQLITE_TRANSIENT);
            } else if ([param isKindOfClass:[NSNumber class]]) {
                NSNumber *num = param;
                sqlite3_bind_int64(compiledStatement, i + 1, [num longLongValue]);
            }
        }
    }
    NSMutableArray *result = [NSMutableArray array];
    while (sqlite3_step(compiledStatement) == SQLITE_ROW) {
        NSMutableArray *row = [NSMutableArray array];
        for (int i = 0; i < sqlite3_column_count(compiledStatement); i++) {
            int colType = sqlite3_column_type(compiledStatement, i);
            id value;
            if (colType == SQLITE_TEXT) {
                const char *col = (const char *)sqlite3_column_text(compiledStatement, i);
                value = [[NSString alloc] initWithUTF8String:col];
            } else if (colType == SQLITE_INTEGER) {
                int col = sqlite3_column_int(compiledStatement, i);
                value = [NSNumber numberWithInt:col];
            } else if (colType == SQLITE_FLOAT) {
                double col = sqlite3_column_double(compiledStatement, i);
                value = [NSNumber numberWithDouble:col];
            } else if (colType == SQLITE_NULL) {
                value = [NSNull null];
            } else {
                NSLog(@"%s Unknown data type.", __FUNCTION__);
            }
            // Add value to row
            [row addObject:value];
            value = nil;
        }
        // Add row to array
        [result addObject:row];
    }
    sqlite3_finalize(compiledStatement);
    return result;
}

@end
