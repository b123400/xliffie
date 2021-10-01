//
//  TranslateServiceWindowController.m
//  Xliffie
//
//  Created by b123400 on 28/12/2015.
//  Copyright © 2015 b123400. All rights reserved.
//

#import "TranslateServiceWindowController.h"
#import "TranslationUtility.h"
#import "MatomoTracker+Shared.h"

@interface TranslateServiceWindowController ()

@property (weak) IBOutlet NSPopUpButton *serviceButton;
@property (weak) IBOutlet NSPopUpButton *translateFilterButton;
@property (weak) IBOutlet NSButton *emptyStringOnlyButton;
@property (weak) IBOutlet NSButton *ignoreEqualButton;
@property (weak) IBOutlet NSTextField *hintTextLabel;
@property (weak) IBOutlet NSButton *okButton;

@property (nonatomic, strong) Document *xliffDocument;
@property (nonatomic, strong) NSArray <NSNumber*> *translationServices;

@end

@implementation TranslateServiceWindowController

- (id)initWithDocument:(Document*)document {
    self = [super initWithWindowNibName:@"TranslateServiceWindowController"];
    self.xliffDocument = document;
    
    NSMutableArray *services = [NSMutableArray array];
    if ([self canTranslateWithService:BRLocaleMapServiceMicrosoft]) {
        [services addObject:@(BRLocaleMapServiceMicrosoft)];
    }
    if ([self canTranslateWithService:BRLocaleMapServiceGoogle]) {
        [services addObject:@(BRLocaleMapServiceGoogle)];
    }
    self.translationServices = services;
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [[self serviceButton] removeAllItems];
    
    for (NSNumber *_service in self.translationServices) {
        BRLocaleMapService service = (BRLocaleMapService)[_service unsignedIntegerValue];
        switch (service) {
            case BRLocaleMapServiceMicrosoft:
                [[self serviceButton] addItemWithTitle:[self nameOfTranslationService:service]];
                break;
            case BRLocaleMapServiceGoogle:
                [[self serviceButton] addItemWithTitle:[self nameOfTranslationService:service]];
                break;
        }
    }
    
    [self configureView];
    
    [[MatomoTracker shared] trackWithView:@[@"TranslateServiceWindowController"] url:nil];
}

- (void)configureView {
    
    if (self.translationServices.count) {
        [[self serviceButton] setEnabled:YES];
    } else {
        [[self serviceButton] setEnabled:NO];
        [[self serviceButton] addItemWithTitle:@"No service available"];
    }
    
    if (self.emptyStringOnlyButton.state == NSOnState) {
        self.ignoreEqualButton.enabled = NO;
    } else {
        self.ignoreEqualButton.enabled = YES;
    }
    
    
    
    if (self.translationServices.count == 0) {
        self.hintTextLabel.stringValue = NSLocalizedString(@"No translation service support this language",
                                                           @"Translation window hint");
        self.okButton.enabled = NO;
    } else if ([self pairsToTranslate].count == 0) {
        self.hintTextLabel.stringValue = NSLocalizedString(@"Nothing matches the above criteria. Nothing will be translated.",
                                                           @"Translation window hint");
        self.okButton.enabled = NO;
    } else {
        self.hintTextLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%lu record(s) are going to be translated using %@.",
                                                                                      @"Translation window hint"),
                                          (unsigned long)[[self pairsToTranslate] count],
                                          [self nameOfTranslationService:[self translationService]]];
        self.okButton.enabled = YES;
    }
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
    TranslationWindowController *controller = [[TranslationWindowController alloc] initWithTranslationPairs:[self pairsToTranslate]
                                                                                         translationService:[self translationService]];
    self.translationWindowController = controller;
    
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

- (NSString*)nameOfTranslationService:(BRLocaleMapService)service {
    switch (service) {
        case BRLocaleMapServiceMicrosoft:
            return @"Bing Translate";
        case BRLocaleMapServiceGoogle:
            return @"Google Translate";
        default:
            return @"Unknown";
    }
}

-(BRLocaleMapService)translationService {
    return [[[self translationServices] objectAtIndex:self.serviceButton.indexOfSelectedItem] unsignedIntegerValue];
}

-(BOOL)canTranslateWithService:(BRLocaleMapService)service {
    return [TranslationUtility isLocale:self.xliffDocument.files[0].sourceLanguage
                    supportedForService:service] &&
           [TranslationUtility isLocale:self.xliffDocument.files[0].targetLanguage
                    supportedForService:service];
}

@end
