//
//  GlossaryFileRow.h
//  Xliffie
//
//  Created by b123400 on 2021/09/28.
//  Copyright © 2021 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GlossaryRow.h"
#import "File.h"

NS_ASSUME_NONNULL_BEGIN

@interface GlossaryFileRow : NSObject

@property (nonatomic, strong) File *file;
@property (nonatomic, strong) NSArray<GlossaryRow*> *rows;

@end

NS_ASSUME_NONNULL_END
