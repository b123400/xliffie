//
//  TranslateServiceWindowController.m
//  Xliffie
//
//  Created by b123400 on 28/12/2015.
//  Copyright © 2015 b123400. All rights reserved.
//

#import "TranslateServiceWindowController.h"
#import "TranslationUtility.h"

@interface TranslateServiceWindowController ()

@property (weak) IBOutlet NSPopUpButton *serviceButton;
@property (weak) IBOutlet NSPopUpButton *translateFilterButton;
@property (weak) IBOutlet NSButton *nonTranslatedStringOnlyButton;
@property (weak) IBOutlet NSButton *ignoreEqualButton;
@property (weak) IBOutlet NSTextField *hintTextLabel;
@property (weak) IBOutlet NSButton *okButton;

@property (nonatomic, strong) Document *xliffDocument;
@property (nonatomic, strong) NSArray<NSNumber *> *translationServices;

@end

@implementation TranslateServiceWindowController

- (id)initWithDocument:(Document*)document {
    self = [super initWithWindowNibName:@"TranslateServiceWindowController"];
    self.xliffDocument = document;
    
    NSMutableArray *services = [NSMutableArray array];
    if ([self canTranslateWithService:XLFTranslationServiceMicrosoft]) {
        [services addObject:@(XLFTranslationServiceMicrosoft)];
    }
    if ([self canTranslateWithService:XLFTranslationServiceGoogle]) {
        [services addObject:@(XLFTranslationServiceGoogle)];
    }
    if ([self canTranslateWithService:XLFTranslationServiceDeepl]) {
        [services addObject:@(XLFTranslationServiceDeepl)];
    }
    if (@available(macOS 26.0, *)) {
        [services addObject:@(XLFTranslationServiceNative)];
    }
    self.translationServices = services;
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [[self serviceButton] removeAllItems];
    
    for (NSNumber *_service in self.translationServices) {
        XLFTranslationService service = (XLFTranslationService)[_service unsignedIntegerValue];
        [[self serviceButton] addItemWithTitle:[self nameOfTranslationService:service]];
    }
    
    [self configureView];
}

- (void)configureView {
    
    if (self.translationServices.count) {
        [[self serviceButton] setEnabled:YES];
    } else {
        [[self serviceButton] setEnabled:NO];
        [[self serviceButton] addItemWithTitle:@"No service available"];
    }
    
    if (self.nonTranslatedStringOnlyButton.state == NSControlStateValueOn) {
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

- (IBAction)nonTranslatedStringOnlyButtonPressed:(id)sender {
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

- (NSArray <TranslationPair*> *)pairsToTranslate {
    return [[self.xliffDocument allTranslationPairs] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(TranslationPair *pair,
                                                                                                         NSDictionary<NSString *,id> * _) {
        
        if (self.translateFilterButton.indexOfSelectedItem == 1) {
            // translate selected only
            if (![self.delegate translateServiceWindowController:self
                                       isTranslationPairSelected:pair]) {
                return NO;
            }
        }
        
        if (self.nonTranslatedStringOnlyButton.state == NSControlStateValueOn && pair.isTranslated) {
            return NO;
        }
        
        if (self.ignoreEqualButton.state == NSControlStateValueOn && [pair.target isEqualToString:pair.source]) {
            return NO;
        }
        
        return YES;
    }]];
}

#pragma mark translation

- (NSString*)nameOfTranslationService:(XLFTranslationService)service {
    switch (service) {
        case XLFTranslationServiceMicrosoft:
            return @"Bing Translate";
        case XLFTranslationServiceGoogle:
            return @"Google Translate";
        case XLFTranslationServiceDeepl:
            return @"DeepL";
        case XLFTranslationServiceNative:
            return @"On-Device Translation";
    }
}

-(XLFTranslationService)translationService {
    return (XLFTranslationService)[[[self translationServices] objectAtIndex:self.serviceButton.indexOfSelectedItem] unsignedIntegerValue];
}

-(BOOL)canTranslateWithService:(XLFTranslationService)service {
    return [TranslationUtility isSourceLocale:self.xliffDocument.files[0].sourceLanguage
                          supportedForService:service] &&
           [TranslationUtility isTargetLocale:self.xliffDocument.files[0].targetLanguage
                          supportedForService:service];
}

@end
