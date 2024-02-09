//
//  CustomGlossaryRow.h
//  Xliffie
//
//  Created by b123400 on 2024/02/08.
//  Copyright © 2024 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomGlossaryRow : NSObject

@property (nonatomic, assign) NSNumber *id;
@property (nonatomic, strong, nullable) NSString *sourceLocale;
@property (nonatomic, strong, nullable) NSString *targetLocale;
@property (nonatomic, strong) NSString *source;
@property (nonatomic, strong) NSString *target;

@end

NS_ASSUME_NONNULL_END
