//
//  CustomGlossaryDatabase.h
//  Xliffie
//
//  Created by b123400 on 2024/02/08.
//  Copyright © 2024 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomGlossaryRow.h"

NS_ASSUME_NONNULL_BEGIN

@interface CustomGlossaryDatabase : NSObject

+ (instancetype)shared;

- (CustomGlossaryRow *)insertWithSourceLocale:(NSString  * _Nullable)sourceLocale
                                 targetLocale:(NSString * _Nullable)targetLocale
                                       source:(NSString *)source
                                       target:(NSString *)target;

- (NSArray<CustomGlossaryRow *> *)deleteRow:(CustomGlossaryRow *)row;

- (CustomGlossaryRow *)updateRow:(CustomGlossaryRow *)row;

- (NSArray<CustomGlossaryRow *> *)rowsWithSourceLocale:(NSString * _Nullable)sourceLocale
                                          targetLocale:(NSString * _Nullable)targetLocale
                                                source:(NSString *)source;
- (NSArray<CustomGlossaryRow *> *)allRows;

@end

NS_ASSUME_NONNULL_END
