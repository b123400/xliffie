//
//  LanguageSet.h
//  Xliffie
//
//  Created by b123400 on 2024/02/08.
//  Copyright © 2024 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LanguageSet : NSObject
// language code, not name
@property NSString *mainLanguage;
@property NSMutableArray <NSString*> *subLanguages;
@end

NS_ASSUME_NONNULL_END
