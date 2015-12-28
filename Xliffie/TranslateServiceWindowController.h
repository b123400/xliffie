//
//  TranslateServiceWindowController.h
//  Xliffie
//
//  Created by b123400 on 28/12/2015.
//  Copyright © 2015 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"
#import "TranslationPair.h"

@protocol TranslateServiceWindowControllerDelegate <NSObject>

- (BOOL)translateServiceWindowController:(id)sender isTranslationPairSelected:(TranslationPair*)pair;

@end

@interface TranslateServiceWindowController : NSWindowController

- (id)initWithDocument:(Document*)document;

@property (weak, nonatomic) id <TranslateServiceWindowControllerDelegate> delegate;

@end
