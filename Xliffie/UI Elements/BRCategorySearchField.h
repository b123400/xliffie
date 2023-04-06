//
//  BRCategorySearchField.h
//  Xliffie
//
//  Created by b123400 on 2023/04/04.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface BRCategorySearchField : NSSearchField

@property (nonatomic, strong) NSArray<NSMenuItem*> *categoryItems;

@end

NS_ASSUME_NONNULL_END
