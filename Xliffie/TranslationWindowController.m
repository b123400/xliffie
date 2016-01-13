//
//  TranslationWindowController.m
//  Xliffie
//
//  Created by b123400 on 13/1/2016.
//  Copyright © 2016 b123400. All rights reserved.
//

#import "TranslationWindowController.h"

@interface TranslationWindowController ()

@property (nonatomic, strong) NSArray *pairs;
@property (nonatomic, assign) BRLocaleMapService service;

@end

@implementation TranslationWindowController

- (instancetype)initWithTranslationPairs:(NSArray <TranslationPair*> *)pairs
                      translationService:(BRLocaleMapService)service {
    self = [super initWithWindowNibName:@"TranslationWindowController"];
    self.pairs = pairs;
    self.service = service;
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
- (IBAction)cancelButtonPressed:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}
- (IBAction)okButtonPressed:(id)sender {
    
}

@end
