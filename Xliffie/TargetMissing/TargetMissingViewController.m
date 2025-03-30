//
//  TargetMissingViewController.m
//  Xliffie
//
//  Created by b123400 on 18/12/2015.
//  Copyright © 2015 b123400. All rights reserved.
//

#import "TargetMissingViewController.h"
#import "File.h"
#import "TranslationUtility.h"
#import "LanguageSet.h"
#import "Utilities.h"

@interface TargetMissingViewController ()

@property (weak) IBOutlet NSPopUpButton *sourceButton;
@property (weak) IBOutlet NSPopUpButton *targetButton;
@property (weak) IBOutlet NSButton *okButton;

@property (nonatomic, strong) NSString *selectedLanguageCode;

@end

@implementation TargetMissingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self configureView];
}

- (void)configureView {
    [self.sourceButton removeAllItems];
    [self.targetButton removeAllItems];
    
    NSMutableOrderedSet *sourceTitles = [NSMutableOrderedSet orderedSet];
    for (File *file in self.document.files) {
        [sourceTitles addObject:[Utilities displayNameForLocaleIdentifier:file.sourceLanguage]];
    }
    
    [self.sourceButton addItemsWithTitles:[sourceTitles array]];
    
    NSMenu *targetLocaleMenu = [[NSMenu alloc] init];
    [Utilities refillMenu:targetLocaleMenu withAllAvailableLocalesWithTarget:self action:@selector(selectedTargetItem:)];
    [self.targetButton setMenu:targetLocaleMenu];
    
    [self.targetButton setTitle:@"Choose language here"];
    self.okButton.enabled = NO;
}

- (void)setDocument:(Document *)document {
    _document = document;
    [self configureView];
}

- (void)selectedTargetItem:(NSMenuItem*)sender {
    [self.targetButton selectItem:sender];
    [self.targetButton setTitle:[sender title]];
    self.okButton.enabled = YES;
    self.selectedLanguageCode = [sender representedObject];
    NSLog(@"Google: %@", [TranslationUtility isTargetLocale:self.selectedLanguageCode
                                  supportedForService:BRLocaleMapServiceGoogle] ? @"YES" : @"NO");
    NSLog(@"MS: %@", [TranslationUtility isTargetLocale:self.selectedLanguageCode
                              supportedForService:BRLocaleMapServiceMicrosoft] ? @"YES" : @"NO");
}

- (IBAction)okClicked:(id)sender {
    if (!self.selectedLanguageCode) return;
    
    for (File *file in self.document.files) {
        file.targetLanguage = self.selectedLanguageCode;
    }
    [self.delegate targetMissingViewController:self
                          didSetTargetLanguage:self.selectedLanguageCode];
}

@end
