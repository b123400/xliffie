//
//  TranslateServiceWindowController.m
//  Xliffie
//
//  Created by b123400 on 28/12/2015.
//  Copyright © 2015 b123400. All rights reserved.
//

#import "TranslateServiceWindowController.h"
#import "TranslationUtility.h"
#import "Xliffie-Swift.h"

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
    if ([self canTranslateWithService:XLFTranslationServiceDeepl]) {
        [services addObject:@(XLFTranslationServiceDeepl)];
    }
    if ([self canTranslateWithService:XLFTranslationServiceGoogle]) {
        [services addObject:@(XLFTranslationServiceGoogle)];
    }
    if ([self canTranslateWithService:XLFTranslationServiceMicrosoft]) {
        [services addObject:@(XLFTranslationServiceMicrosoft)];
    }
    // On-Device Translation availability is checked asynchronously in windowDidLoad.
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
    [self checkNativeTranslationSupport];
}

- (void)configureView {
    
    if (self.translationServices.count) {
        [[self serviceButton] setEnabled:YES];
    } else {
        [[self serviceButton] setEnabled:NO];
        [[self serviceButton] addItemWithTitle:NSLocalizedString(@"No service available", @"Translation service window")];
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
    if ([self translationService] != XLFTranslationServiceNative) {
        [self beginTranslation];
        return;
    }

    if (@available(macOS 26.0, *)) {
        // For On-Device Translation, check whether the language model needs downloading first.
        self.okButton.enabled = NO;

        NSString *source = self.xliffDocument.files[0].sourceLanguage;
        NSString *target = self.xliffDocument.files[0].targetLanguage;

        [TranslationUtility needsDownloadForSourceLocale:source
                                            targetLocale:target
                                                 service:XLFTranslationServiceNative
                                       completionHandler:^(BOOL needsDownload) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!needsDownload) {
                    [self beginTranslation];
                    return;
                }
                // Trigger the system download UI then proceed when ready.
                [NativeTranslator downloadInViewWithHost:self.window.contentView
                                                  source:source
                                                  target:target
                                              completion:^(NSError * _Nullable error) {

                    [TranslationUtility needsDownloadForSourceLocale:source
                                                        targetLocale:target
                                                             service:XLFTranslationServiceNative
                                                   completionHandler:^(BOOL needsDownload) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.okButton.enabled = YES;
                            if (needsDownload) {
                                // Need download after download = download cancelled
                                return;
                            }
                            if (error) {
                                NSAlert *alert = [NSAlert alertWithError:error];
                                [alert beginSheetModalForWindow:self.window completionHandler:nil];
                            } else {
                                [self beginTranslation];
                            }
                        });
                    }];
                }];
            });
        }];
    }
}

- (void)beginTranslation {
    TranslationWindowController *controller = [[TranslationWindowController alloc] initWithTranslationPairs:[self pairsToTranslate]
                                                                                         translationService:[self translationService]];
    self.translationWindowController = controller;

    [self.window.sheetParent endSheet:self.window
                           returnCode:NSModalResponseOK];
}

#pragma mark - native translation support check

/// Asynchronously determines whether On-Device Translation can handle the document's
/// locale pair, then adds it to the service list if so (macOS 26+ only).
- (void)checkNativeTranslationSupport {
    if (@available(macOS 26.0, *)) {
        NSString *source = self.xliffDocument.files[0].sourceLanguage;
        NSString *target = self.xliffDocument.files[0].targetLanguage;

        [TranslationUtility needsDownloadForSourceLocale:source
                                            targetLocale:target
                                                 service:XLFTranslationServiceNative
                                       completionHandler:^(BOOL needsDownload) {
            if (!needsDownload) {
                // Already installed — add native immediately.
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self addNativeToServices];
                });
            } else {
                // Model not installed; check whether it can be downloaded.
                [TranslationUtility isSourceLocale:source
                                      targetLocale:target
                               supportedForService:XLFTranslationServiceNative
                                 completionHandler:^(BOOL isSupported) {
                    if (isSupported) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self addNativeToServices];
                        });
                    }
                    // isSupported == NO means the pair is unsupported; don't add.
                }];
            }
        }];
    }
}

- (void)addNativeToServices {
    NSMutableArray *services = [self.translationServices mutableCopy];
    [services insertObject:@(XLFTranslationServiceNative) atIndex:0];
    self.translationServices = services;
    [[self serviceButton] insertItemWithTitle:[self nameOfTranslationService:XLFTranslationServiceNative] atIndex:0];
    [[self serviceButton] selectItemAtIndex:0];
    [self configureView];
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
            return NSLocalizedString(@"Bing Translate", @"");
        case XLFTranslationServiceGoogle:
            return NSLocalizedString(@"Google Translate", @"");
        case XLFTranslationServiceDeepl:
            return NSLocalizedString(@"DeepL", @"");
        case XLFTranslationServiceNative:
            return NSLocalizedString(@"On-Device Translation", @"");
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
