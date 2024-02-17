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

@interface CustomGlossaryDatabase : NSObject <CustomGlossaryImporterDelegate>

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

- (void)exportToFile:(NSString *)path;
- (void)importWithFile:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
