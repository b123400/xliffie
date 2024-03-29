//
//  CustomGlossaryDatabase.h
//  Xliffie
//
//  Created by b123400 on 2024/02/08.
//  Copyright © 2024 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomGlossaryRow.h"
#import "CustomGlossaryImporter.h"

NS_ASSUME_NONNULL_BEGIN

#define CUSTOM_GLOSSARY_DATABASE_UPDATED_NOTIFICATION @"CUSTOM_GLOSSARY_DATABASE_UPDATED_NOTIFICATION"

@interface CustomGlossaryDatabase : NSObject <CustomGlossaryImporterDelegate>

@property (nonatomic, assign) BOOL notificationEnabled;

+ (instancetype)shared;

- (CustomGlossaryRow *)insertWithSourceLocale:(NSString  * _Nullable)sourceLocale
                                 targetLocale:(NSString * _Nullable)targetLocale
                                       source:(NSString *)source
                                       target:(NSString *)target;

- (void)deleteRow:(CustomGlossaryRow *)row;

- (void)updateRow:(CustomGlossaryRow *)row;

- (NSArray<CustomGlossaryRow *> *)rowsWithSourceLocale:(NSString * _Nullable)sourceLocale
                                          targetLocale:(NSString * _Nullable)targetLocale
                                                source:(NSString *)source;
- (NSArray<CustomGlossaryRow *> *)allRows;

- (BOOL)doesRowExistWithSourceLocale:(NSString * _Nullable)sourceLocale
                        targetLocale:(NSString * _Nullable)targetLocale
                              source:(NSString *)source
                              target:(NSString *)target;

- (NSProgress *)exportToFile:(NSString *)path
              withTotalCount:(int64_t)total
                    callback:(void (^)(NSError *error))callback;
- (NSProgress *)importWithFile:(NSURL *)url callback:(void (^)(NSError *error))callback;

@end

NS_ASSUME_NONNULL_END
