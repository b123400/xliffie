//
//  CustomGlossaryDatabase.m
//  Xliffie
//
//  Created by b123400 on 2024/02/08.
//  Copyright © 2024 b123400. All rights reserved.
//

#import "CustomGlossaryDatabase.h"
#import <sqlite3.h>

@implementation CustomGlossaryDatabase {
    sqlite3 *_sqlite;
}

+ (instancetype)shared {
    static CustomGlossaryDatabase *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[CustomGlossaryDatabase alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        [self open];
    }
    return self;
}

- (NSString *)databasePath {
    NSArray<NSURL *> *documentPaths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSString *docPath = [[documentPaths lastObject] path];
    NSString *dbPath = [docPath stringByAppendingPathComponent:@"custom_glossary.db"];
    NSLog(@"custom db path %@", dbPath);
    return dbPath;
}

- (BOOL)open {
    if (_sqlite) return YES;

    sqlite3 *dbConnection = nil;
    int rc = sqlite3_open_v2([self.databasePath UTF8String], &dbConnection, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
    if (rc != SQLITE_OK) {
        return NO;
    }
    _sqlite = dbConnection;
    NSArray *createTableResult = [self query:@"CREATE TABLE IF NOT EXISTS glossary (id INTEGER PRIMARY KEY AUTOINCREMENT, source_locale varchar(255) NULL, target_locale varchar(255) NULL, source text NOT NULL, target text NOT NULL);" withParams:@[]];
    NSLog(@"createTableResult %@", createTableResult);
    return YES;
}

- (CustomGlossaryRow *)insertWithSourceLocale:(NSString  * _Nullable)sourceLocale
                                 targetLocale:(NSString * _Nullable)targetLocale
                                       source:(NSString *)source
                                       target:(NSString *)target {
    NSArray *insertResult = [self query:@"INSERT INTO glossary (source_locale, target_locale, source, target) VALUES (?, ?, ?, ?)" withParams:@[
        sourceLocale ?: [NSNull null],
        targetLocale ?: [NSNull null],
        source,
        target,
    ]];
    NSLog(@"insertResult %@", insertResult);
    return nil;
}

- (NSArray<CustomGlossaryRow *> *)deleteRow:(CustomGlossaryRow *)row {
    NSArray *deleteResult = [self query:@"DELETE FROM glossary WHERE id = ?" withParams:@[row.id]];
    NSLog(@"deleteResult %@", deleteResult);
    return nil;
}

- (CustomGlossaryRow *)updateRow:(CustomGlossaryRow *)row {
    NSArray *updateResult = [self query:@"UPDATE glossary SET source_locale = ?, target_locale = ?, source = ?, target = ? WHERE id = ?" withParams:@[
        row.sourceLocale ?: [NSNull null],
        row.targetLocale ?: [NSNull null],
        row.source,
        row.target,
        row.id,
    ]];
    NSLog(@"updateResult %@", updateResult);
    return nil;
}

- (NSArray<CustomGlossaryRow *> *)rowsWithSourceLocale:(NSString * _Nullable)sourceLocale
                                          targetLocale:(NSString * _Nullable)targetLocale
                                                source:(NSString *)source {
    NSArray *rows = [self query:@"SELECT id, source_locale, target_locale, source, target FROM glossary WHERE (source_locale = ? OR source_locale IS NULL) AND (target_locale = ? OR target_locale IS NULL) AND source = ?" withParams:@[
        sourceLocale ?: [NSNull null],
        targetLocale ?: [NSNull null],
        source
    ]];
    return [self rowsToObjects:rows];
}

- (NSArray<CustomGlossaryRow *> *)allRows {
    NSArray *rows = [self query:@"SELECT id, source_locale, target_locale, source, target FROM glossary" withParams:@[]];
    return [self rowsToObjects:rows];
}

- (NSArray<CustomGlossaryRow *> *)rowsToObjects:(NSArray *)rows {
    NSMutableArray<CustomGlossaryRow*> *results = [NSMutableArray array];
    for (NSArray *columns in rows) {
        CustomGlossaryRow *r = [[CustomGlossaryRow alloc] init];
        r.id = columns[0];
        r.sourceLocale = [columns[1] isKindOfClass:[NSNull class]] ? nil : columns[1];
        r.targetLocale = [columns[2] isKindOfClass:[NSNull class]] ? nil : columns[2];
        r.source = columns[3];
        r.target = columns[4];
        [results addObject:r];
    }
    return results;
}

- (NSArray<NSArray*> *)query:(NSString *)sql withParams:(NSArray * _Nullable)params {
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
            } else if ([param isKindOfClass:[NSNull class]]) {
                sqlite3_bind_null(compiledStatement, i + 1);
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
