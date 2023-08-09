//
//  SuggestionLoadingCellView.m
//  Xliffie
//
//  Created by b123400 on 2023/08/09.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "SuggestionLoadingCellView.h"

@implementation SuggestionLoadingCellView

- (void)awakeFromNib {
    [self.loadingSign startAnimation:self];
}

@end
