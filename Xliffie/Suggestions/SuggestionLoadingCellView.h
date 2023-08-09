//
//  SuggestionLoadingCellView.h
//  Xliffie
//
//  Created by b123400 on 2023/08/09.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SuggestionLoadingCellView : NSTableCellView

@property (weak) IBOutlet NSProgressIndicator *loadingSign;

@end

NS_ASSUME_NONNULL_END
