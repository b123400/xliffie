//
//  SuggestionsWindowController.h
//  Xliffie
//
//  Created by b123400 on 2022/12/05.
//  Copyright © 2022 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Suggestion.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SuggestionsWindowControllerDelegate

- (void)suggestionWindowController:(id)controller didSelectSuggestion:(Suggestion *)suggestion;

@end

@interface SuggestionsWindowController : NSWindowController

@property (nonatomic, strong) NSArray<Suggestion *> *suggestions;
@property (nonatomic, weak) id<SuggestionsWindowControllerDelegate> delegate;
@property (nonatomic, weak) id searchingObject;

+ (instancetype)shared;

- (void)showAtRect:(NSRect)rect ofView:(NSView *)view;
- (void)hide;
- (Suggestion *)selectedSuggestion;

@end

NS_ASSUME_NONNULL_END
