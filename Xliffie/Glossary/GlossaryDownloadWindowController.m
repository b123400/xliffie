//
//  GlossaryDownloadWindowController.m
//  Xliffie
//
//  Created by b123400 on 2023/07/29.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "GlossaryDownloadWindowController.h"
#import "GlossaryDatabase.h"

@interface GlossaryDownloadWindowController ()
@property (weak) IBOutlet NSButton *macOSXButton;
@property (weak) IBOutlet NSButton *iOSButton;
@property (weak) IBOutlet NSPopUpButton *localeButton;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSButton *downloadButton;

@property (assign, nonatomic) GlossaryPlatform platform;
@property (strong, nonatomic) GlossaryDatabase *downloadingDatabase;

@end

@implementation GlossaryDownloadWindowController

- (instancetype)init {
    if (self = [super initWithWindowNibName:@"GlossaryDownloadWindowController"]) {
        self.platform = GlossaryPlatformIOS;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self reloadLocales];
}

- (void)reloadLocales {
    NSMutableArray<NSMenuItem *> *items = [NSMutableArray array];
    for (NSString *locale in [GlossaryDatabase localesWithPlatform:self.platform]) {
        GlossaryDatabase *db = [GlossaryDatabase databaseWithPlatform:self.platform locale:locale];
        if (![db isDownloaded]) {
            NSMenuItem *item = [[NSMenuItem alloc] init];
            [item setTitle:locale];
            [items addObject:item];
        }
    }
    [self.localeButton.menu setItemArray:items];
}

- (IBAction)platformClicked:(id)sender {
    if (sender == self.macOSXButton) {
        self.platform = GlossaryPlatformMac;
    } else if (sender == self.iOSButton) {
        self.platform = GlossaryPlatformIOS;
    }
    [self reloadLocales];
}
- (IBAction)localeClicked:(id)sender {
//    NSMenuItem *item = [self.localeButton selectedItem];
//    self.locale = [item title];
}
- (IBAction)downloadClicked:(id)sender {
    [self.downloadButton setTitle:NSLocalizedString(@"Downloading...", @"")];
    [self.progressIndicator setHidden:NO];
    self.iOSButton.enabled = self.macOSXButton.enabled = self.downloadButton.enabled = self.localeButton.enabled = NO;
    GlossaryDatabase *db = [GlossaryDatabase databaseWithPlatform:self.platform locale:[self.localeButton.selectedItem title]];
    self.downloadingDatabase = db;
    __weak typeof(self) _self = self;
    NSProgress *progress = [db download:^(NSError * _Nonnull error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (error && error.code != -999) {
                [[NSAlert alertWithError:error] runModal];
                return;
            }
            [_self.window.sheetParent endSheet:_self.window
                                    returnCode:NSModalResponseOK];
        });
    }];
    [progress addObserver:self
               forKeyPath:@"fractionCompleted"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    __weak typeof(self) _self = self;
    if ([keyPath isEqual:@"fractionCompleted"] && [object isKindOfClass:[NSProgress class]]) {
        NSNumber *percentage = change[NSKeyValueChangeNewKey];
        if (![percentage isKindOfClass:[NSNumber class]]) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_self.progressIndicator setDoubleValue:percentage.doubleValue * 100];
        });
    }
}

- (IBAction)cancelClicked:(id)sender {
    [self.downloadingDatabase cancelDownload];
    [self.window.sheetParent endSheet:self.window
                           returnCode:NSModalResponseCancel];
}

@end
