//
//  GlossaryDatabase.m
//  Xliffie
//
//  Created by b123400 on 2023/07/12.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "GlossaryDatabase.h"
#import <sqlite3.h>
#import "GlossaryReverseSearchResult.h"
#import "Utilities.h"

@interface GlossaryDatabase ()

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

@end

@implementation GlossaryDatabase {
    sqlite3 *_sqlite;
}

+ (GlossaryDatabase *)databaseWithPlatform:(GlossaryPlatform)platform locale:(NSString *)locale {
    static NSMutableDictionary<NSString *, GlossaryDatabase *> *iosDatabases = nil;
    static NSMutableDictionary<NSString *, GlossaryDatabase *> *macDatabases = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        iosDatabases = [NSMutableDictionary dictionary];
        macDatabases = [NSMutableDictionary dictionary];
    });
    NSMutableDictionary<NSString *, GlossaryDatabase *> *dict = platform == GlossaryPlatformIOS ? iosDatabases : macDatabases;
    if (dict[locale]) {
        return dict[locale];
    }
    GlossaryDatabase *db = [[GlossaryDatabase alloc] initWithPlatform:platform locale:locale];
    dict[locale] = db;
    return db;
}

+ (NSArray<GlossaryDatabase*> *)downloadedDatabasesWithPlatform:(GlossaryPlatform)platform {
    NSArray<NSString*> *allLocales = [GlossaryDatabase localesWithPlatform:platform];
    NSMutableArray<GlossaryDatabase*> *dbs = [NSMutableArray array];
    for (NSString *locale in allLocales) {
        GlossaryDatabase *db = [GlossaryDatabase databaseWithPlatform:platform locale:locale];
        if ([db isDownloaded]) {
            [dbs addObject:db];
        }
    }
    return dbs;
}

+ (NSArray<NSString*>*)localesWithPlatform:(GlossaryPlatform)platform {
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
    return @[];
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
    return @[];
}

+ (NSArray<NSString*> *)relatedDatabaseForLocale:(NSString *)locale withPlatform:(GlossaryPlatform)platform {
    NSArray<NSString*> *dbs = [GlossaryDatabase localesWithPlatform:platform];
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

+ (NSArray<GlossaryDatabase *> *)allRelatedDatabasesWithLocale:(NSString *)locale platform:(GlossaryPlatform)platform extraLocales:(NSArray<NSString*> *)extraLocales{
    if (platform == GlossaryPlatformAny) {
        return [[self allRelatedDatabasesWithLocale:locale platform:GlossaryPlatformMac extraLocales:extraLocales]
                arrayByAddingObjectsFromArray:[self allRelatedDatabasesWithLocale:locale platform:GlossaryPlatformIOS extraLocales:extraLocales]];
    }
    NSMutableOrderedSet<NSString *> *locales = [NSMutableOrderedSet orderedSet];
    [locales addObject:locale];
    [locales addObjectsFromArray:[self recommendedRelatedDatabaseForLocale:locale withPlatform:platform]];
    [locales addObjectsFromArray:[self relatedDatabaseForLocale:locale withPlatform:platform]];
    [locales addObjectsFromArray:extraLocales];
    NSMutableArray *dbs = [NSMutableArray array];
    for (NSString *locale in locales) {
        GlossaryDatabase *db = [GlossaryDatabase databaseWithPlatform:platform locale:locale];
        if ([db isDownloaded]) {
            [dbs addObject:db];
        }
    }
    return dbs;
}

+ (dispatch_queue_t)dispatchQueue {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_attr_t queueAttrs = dispatch_queue_attr_make_with_qos_class(
            DISPATCH_QUEUE_SERIAL,
            QOS_CLASS_USER_INITIATED /* Same as DISPATCH_QUEUE_PRIORITY_HIGH */,
            0
        );
        queue = dispatch_queue_create("net.b123400.xliffie.glossary", queueAttrs);
    });
    return queue;
}

+ (void)searchGlossariesForTerms:(NSArray<NSString *> *)terms
                    withPlatform:(GlossaryPlatform)platform
                      fromLocale:(NSString *)sourceLocale
                        toLocale:(NSString *)targetLocale
                        callback:(void(^)(GlossarySearchResults *results))callback {
    dispatch_async([GlossaryDatabase dispatchQueue], ^{
        GlossarySearchResults *results = [GlossarySearchResults new];
        NSArray<GlossaryDatabase *> *targetDatabases = [GlossaryDatabase allRelatedDatabasesWithLocale:targetLocale platform:platform extraLocales:@[]];
        
        BOOL anyTargetDBDownloaded = NO;
        for (GlossaryDatabase *targetDatabase in targetDatabases) {
            if ([targetDatabase isDownloaded]) {
                anyTargetDBDownloaded = YES;
                NSDictionary<NSString *, NSArray<GlossarySearchRow*>*> *targetDBResults = [targetDatabase findTargetsWithSources:terms];
                for (NSString *source in targetDBResults) {
                    NSArray<GlossarySearchRow*> *targetsInDB = targetDBResults[source];
                    [results addSearchResults:targetsInDB];
                }
            }
        }
        
        if (!anyTargetDBDownloaded) {
            callback(results);
            return;
        }
        
        NSArray<GlossaryDatabase *> *sourceDatabases = [GlossaryDatabase allRelatedDatabasesWithLocale:sourceLocale platform:platform extraLocales:@[@"en", @"English", @"Base"]];
        NSMutableDictionary<GlossaryReverseSearchResult*, NSString *> *reverseResults = [NSMutableDictionary dictionary];
        for (GlossaryDatabase *sourceDatabase in sourceDatabases) {
            if ([sourceDatabase isDownloaded]) {
                NSDictionary<GlossaryReverseSearchResult*, NSString*> *thisReverseResults = [sourceDatabase findRowsWithTargets:terms];
                [reverseResults addEntriesFromDictionary:thisReverseResults];
            }
        }
        for (GlossaryDatabase *targetDatabase in targetDatabases) {
            if ([targetDatabase isDownloaded]) {
                NSDictionary<GlossaryReverseSearchResult *, NSString*> *newTargets = [targetDatabase findTargetsWithReverseResults:[reverseResults allKeys]];
                for (GlossaryReverseSearchResult *revResult in newTargets) {
                    NSString *sourceResult = reverseResults[revResult];
                    NSString *newTarget = newTargets[revResult];
                    if (sourceResult && newTarget) {
                        [results addResultWithSource:sourceResult target:newTarget bundlePath:revResult.bundlePath];
                    }
                }
            }
        }
        callback(results);
    });
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
        _self.downloadTask = nil;
        if (error) {
            callback(error);
            return;
        }
        NSError *err = nil;
        [[NSFileManager defaultManager] copyItemAtURL:location
                                                toURL:[NSURL fileURLWithPath:_self.databasePath]
                                                error:&err];
        if (![_self testDatabase]) {
            [[NSFileManager defaultManager] removeItemAtPath:_self.databasePath error:nil];
            err = [NSError errorWithDomain:@"net.b123400.xliffie" code:0 userInfo:@{
                NSLocalizedDescriptionKey: NSLocalizedString(@"Database corrupted", @"")
            }];
            callback(err);
            return;
        }
        if (err) {
            callback(err);
            return;
        }
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

- (void)close {
    if (!_sqlite) return;
    sqlite3_close_v2(_sqlite);
    _sqlite = nil;
}

- (unsigned long long)fileSize {
    NSError *error = nil;
    NSDictionary<NSFileAttributeKey, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.databasePath
                                                                                                       error:&error];
    if (error) {
        NSLog(@"Cannot stat %@", self.databasePath);
        return 0;
    }
    return [attributes fileSize];
}

- (BOOL)testDatabase {
    NSArray *rows = [self query:@"SELECT source, target, bundle_path FROM translations LIMIT 1" withParams:@[]];
    if (rows.count == 1) {
        return YES;
    }
    return NO;
}

- (NSArray *)findTargetsWithSource:(NSString *)source {
    return [self query:@"SELECT target FROM translations WHERE source = ?" withParams:@[source]];
}

- (NSDictionary<NSString *, NSArray<GlossarySearchRow *> *> *)findTargetsWithSources:(NSArray<NSString *> *)sources {
    if (!sources.count) return @{};
    // Max num of place holder is 999: https://www.sqlite.org/limits.html
    NSArray *batches = [Utilities  batch:sources limit:999 callback:^id(NSArray *items) {
        NSMutableArray *placeHolders = [NSMutableArray arrayWithCapacity:items.count];
        for (int i = 0; i < items.count; i++) {
            [placeHolders addObject:@"?"];
        }
        NSString *sql = [NSString stringWithFormat:@"SELECT source, target, bundle_path FROM translations WHERE source IN (%@)", [placeHolders componentsJoinedByString:@","]];
        NSArray *targets = [self query:sql withParams:items];
        return targets;
    }];
    NSArray *rows = [batches valueForKeyPath: @"@unionOfArrays.self"];
    NSMutableDictionary<NSString*, NSMutableArray<GlossarySearchRow*>*> *dict = [NSMutableDictionary dictionary];
    for (NSArray *row in rows) {
        NSString *source = row[0];
        NSString *target = row[1];
        NSString *bundlePath = row[2];
        if (!dict[source]) {
            dict[source] = [NSMutableArray array];
        }
        GlossarySearchRow *r = [GlossarySearchRow new];
        r.source = source;
        r.target = target;
        r.bundlePath = bundlePath;
        [dict[source] addObject:r];
    };
    return dict;
}

- (NSArray *)findRowsWithTarget:(NSString *)target {
    return [self query:@"SELECT source, target, bundle_path FROM translations WHERE target = ?" withParams:@[target]];
}

- (NSDictionary<GlossaryReverseSearchResult*, NSString*> *)findRowsWithTargets:(NSArray<NSString *> *)targets {
    NSArray *batches = [Utilities  batch:targets limit:999 callback:^id(NSArray *items) {
        NSMutableArray *placeHolders = [NSMutableArray arrayWithCapacity:items.count];
        for (int i = 0; i < items.count; i++) {
            [placeHolders addObject:@"?"];
        }
        NSString *sql = [NSString stringWithFormat:@"SELECT source, target, bundle_path FROM translations WHERE target IN (%@)", [placeHolders componentsJoinedByString:@","]];
        NSArray *targets = [self query:sql withParams:items];
        return targets;
    }];
    NSArray *rows = [batches valueForKeyPath: @"@unionOfArrays.self"];
    NSMutableDictionary<GlossaryReverseSearchResult*, NSString*> *dict = [NSMutableDictionary dictionary];
    for (NSArray *row in rows) {
        NSString *source = row[0];
        NSString *target = row[1];
        NSString *bundlePath = row[2];
        GlossaryReverseSearchResult *r = [GlossaryReverseSearchResult new];
        r.source = source;
        r.bundlePath = bundlePath;
        dict[r] = target;
    };
    return dict;
}

- (NSArray *)findTargetsWithSource:(NSString *)source andBundlePath:(NSString *)bundlePath {
    return [self query:@"SELECT target FROM translations WHERE source = ? AND bundle_path = ?" withParams:@[source, bundlePath]];
}

- (NSDictionary<GlossaryReverseSearchResult *, NSString *> *)findTargetsWithReverseResults:(NSArray<GlossaryReverseSearchResult*>*)reverseResults {
    NSArray *batches = [Utilities  batch:reverseResults limit:498 callback:^id(NSArray<GlossaryReverseSearchResult*> *items) {
        NSMutableArray *placeHolders = [NSMutableArray arrayWithCapacity:items.count];
        NSMutableArray *values = [NSMutableArray arrayWithCapacity:items.count];
        for (int i = 0; i < items.count; i++) {
            [placeHolders addObject:[NSString stringWithFormat:@" (source = ? AND bundle_path = ?) "]];
            [values addObjectsFromArray:@[items[i].source, items[i].bundlePath]];
        }
        NSString *sql = [NSString stringWithFormat:@"SELECT source, target, bundle_path FROM translations WHERE %@", [placeHolders componentsJoinedByString:@" OR "]];
        NSArray *results = [self query:sql withParams:values];
        return results;
    }];
    NSArray *rows = [batches valueForKeyPath: @"@unionOfArrays.self"];
    NSMutableDictionary<GlossaryReverseSearchResult *, NSString *> *dict = [NSMutableDictionary dictionary];
    for (NSArray *row in rows) {
        NSString *source = row[0];
        NSString *target = row[1];
        NSString *bundlePath = row[2];
        GlossaryReverseSearchResult *revResult = [GlossaryReverseSearchResult new];
        revResult.source = source;
        revResult.bundlePath = bundlePath;
        dict[revResult] = target;
    }
    return dict;
}

- (NSArray *)query:(NSString *)sql withParams:(NSArray * _Nullable)params {
    if (![self open]) return nil;
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

- (void)deleteDatabase {
    if (![self isDownloaded]) return;
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[self databasePath] error:&error];
    if (error) {
        NSLog(@"Cannot delete DB %@", error);
    }
}

@end
