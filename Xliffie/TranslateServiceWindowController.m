//
//  TranslateServiceWindowController.m
//  Xliffie
//
//  Created by b123400 on 28/12/2015.
//  Copyright © 2015 b123400. All rights reserved.
//

#import "TranslateServiceWindowController.h"

@interface TranslateServiceWindowController ()

@property (weak) IBOutlet NSPopUpButton *serviceButton;
@property (weak) IBOutlet NSPopUpButton *translateFilterButton;
@property (weak) IBOutlet NSButton *emptyStringOnlyButton;
@property (weak) IBOutlet NSButton *ignoreEqualButton;
@property (weak) IBOutlet NSTextField *hintTextLabel;

@property (nonatomic, strong) Document *xliffDocument;

@end

@implementation TranslateServiceWindowController

- (id)initWithDocument:(Document*)document {
    self = [super initWithWindowNibName:@"TranslateServiceWindowController"];
    self.xliffDocument = document;
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [self configureView];
}

- (void)configureView {
    if (self.emptyStringOnlyButton.state == NSOnState) {
        self.ignoreEqualButton.enabled = NO;
    } else {
        self.ignoreEqualButton.enabled = YES;
    }
    self.hintTextLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%d record(s) are going to be translated using %@.",
                                                                                  @"Translation window hint"),
                                      [[self pairsToTranslate] count],
                                      [self nameOfTranslationService]];
}

- (IBAction)serviceButtonPressed:(id)sender {
    [self configureView];
}

- (IBAction)translateFilterButtonPressed:(id)sender {
    [self configureView];
}

- (IBAction)emptyStringOnlyButtonPressed:(id)sender {
    [self configureView];
}

- (IBAction)ignoreEqualButtonPressed:(id)sender {
    [self configureView];
}

- (IBAction)cancelPressed:(id)sender {
    [self.window.sheetParent endSheet:self.window
                           returnCode:NSModalResponseCancel];
}

- (IBAction)okPressed:(id)sender {
    [self.window.sheetParent endSheet:self.window
                           returnCode:NSModalResponseOK];
}

#pragma mark - document

- (NSArray <TranslationPair*> *)allTranslationPairs {
    NSMutableArray *pairs = [NSMutableArray array];
    for (File *file in self.xliffDocument.files) {
        [pairs addObjectsFromArray:file.translations];
    }
    return pairs;
}

- (NSArray <TranslationPair*> *)pairsToTranslate {
    return [[self allTranslationPairs] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(TranslationPair *pair,
                                                                                                         NSDictionary<NSString *,id> * _) {
        
        if (self.translateFilterButton.indexOfSelectedItem == 1) {
            // translate selected only
            if (![self.delegate translateServiceWindowController:self
                                       isTranslationPairSelected:pair]) {
                return NO;
            }
        }
        
        if (self.emptyStringOnlyButton.state == NSOnState &&
            !(!pair.target || [pair.target isEqualToString:@""])) {
            return NO;
        }
        
        if (self.ignoreEqualButton.state == NSOnState && [pair.target isEqualToString:pair.source]) {
            return NO;
        }
        
        return YES;
    }]];
}

#pragma mark translation

- (NSString*)nameOfTranslationService {
    switch (self.serviceButton.indexOfSelectedItem) {
        case 0:
            return @"Bing Translate";
        case 1:
            return @"Google Translate";
        default:
            return @"Unknown";
    }
}

@end
