//
//  NSAttributedString+FileIcon.h
//  Xliffie
//
//  Created by b123400 on 2022/12/06.
//  Copyright © 2022 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAttributedString (FileIcon)

+ (NSAttributedString *)attributedStringWithFileIcon:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
