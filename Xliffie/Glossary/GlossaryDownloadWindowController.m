//
//  GlossaryDownloadWindowController.m
//  Xliffie
//
//  Created by b123400 on 2023/07/29.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "GlossaryDownloadWindowController.h"

@interface GlossaryDownloadWindowController ()<NSOutlineViewDelegate, NSOutlineViewDataSource>
@property (weak) IBOutlet NSSegmentedControl *platformSegment;
@property (weak) IBOutlet NSOutlineView *outlineView;

@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSButton *downloadButton;
@property (weak) IBOutlet NSTextField *glossaryDescriptionLabel;

// User Input
@property (strong, nonatomic) NSArray<NSString*> *preferediOSLocales;
@property (strong, nonatomic) NSArray<NSString*> *preferedMacOSLocales;
@property (assign, nonatomic) GlossaryPlatform selectedPlatform;
// Calculated, visible Output
@property (strong, nonatomic) NSArray<NSString*> *relatedLocales;
@property (strong, nonatomic) NSArray<NSString*> *otherAvailableLocales;
@property (strong, nonatomic) NSMutableSet<NSString*> *selectedLocales;
@property (strong, nonatomic) GlossaryDatabase *downloadingDatabase;

@property (strong, nonatomic) NSProgress *progress;
@property (strong, nonatomic) NSMutableArray<NSString*> *localesDownloadQueue;

@end

@implementation GlossaryDownloadWindowController

- (instancetype)initWithiOSLocales:(NSArray<NSString *> *)iOSLocales macOSLocales:(NSArray<NSString*> *)macOSLocales {
    if (self = [super initWithWindowNibName:@"GlossaryDownloadWindowController"]) {
        self.preferediOSLocales = iOSLocales;
        self.preferedMacOSLocales = macOSLocales;
        self.selectedPlatform = iOSLocales.count > macOSLocales.count ? GlossaryPlatformIOS : GlossaryPlatformMac;
        [self calculateLocales];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSString *baseStr = NSLocalizedString(@"These databases are generated with the same source of applelocalization.com, you can read more about the that here",@"");
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:baseStr attributes:@{
        NSForegroundColorAttributeName: [NSColor secondaryLabelColor],
        NSFontAttributeName: self.glossaryDescriptionLabel.font,
    }];
    [str addAttributes:@{NSLinkAttributeName: [NSURL URLWithString:@"https://applelocalization.com"]} range:[baseStr rangeOfString:@"applelocalization.com"]];
    [str addAttributes:@{NSLinkAttributeName: [NSURL URLWithString:@"https://b123400.net/xliffie/glosseries"]} range:[baseStr rangeOfString:@"here"]];
    
    self.glossaryDescriptionLabel.attributedStringValue = str;
    [self.outlineView expandItem:nil expandChildren:YES];
    
    if (self.selectedPlatform == GlossaryPlatformIOS) {
        [self.platformSegment setSelectedSegment:0];
    } else if (self.selectedPlatform == GlossaryPlatformMac) {
        [self.platformSegment setSelectedSegment:1];
    }
}

- (void)calculateLocales {
    self.selectedLocales = [NSMutableSet set];
    NSArray<NSString *> *allLocales = [GlossaryDatabase localesWithPlatform:self.selectedPlatform];
    NSSet<NSString *> *downloadedLocales = [NSSet setWithArray:[[GlossaryDatabase downloadedDatabasesWithPlatform:self.selectedPlatform] valueForKeyPath:@"locale"]];
    NSMutableOrderedSet *relatedLocales = [NSMutableOrderedSet orderedSet];
    NSArray<NSString*> *preferredLocales =
        self.selectedPlatform == GlossaryPlatformIOS ? self.preferediOSLocales :
        self.selectedPlatform == GlossaryPlatformMac ? self.preferedMacOSLocales : @[];
    
    // Find the locales that matches exactly (w/o considering -_) and select them
    for (NSString *preferredLocale in preferredLocales) {
        NSString *replacedPreferred = [[[preferredLocale componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-_"]] componentsJoinedByString:@"_"] lowercaseString];
        for (NSString *locale in allLocales) {
            NSString *replacedAll = [[[locale componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-_"]] componentsJoinedByString:@"_"] lowercaseString];
            if ([replacedPreferred isEqual:replacedAll]) {
                if (![downloadedLocales containsObject:locale]) {
                    [relatedLocales addObject:locale];
                    [self.selectedLocales addObject:locale];
                }
                break;
            }
        }
    }
    // Find recommended locales based on the ones selected
    for (NSString *preferredLocale in [relatedLocales array]) {
        for (NSString *recommended in [GlossaryDatabase recommendedRelatedDatabaseForLocale:preferredLocale withPlatform:self.selectedPlatform]) {
            if (![downloadedLocales containsObject:recommended]) {
                [relatedLocales addObject:recommended];
                [self.selectedLocales addObject:recommended];
            }
        }
    }
    for (NSString *recommended in @[@"en", @"Base"]) {
        if (![downloadedLocales containsObject:recommended]) {
            [relatedLocales addObject:recommended];
            [self.selectedLocales addObject:recommended];
        }
    }
    // Related but not necessarily recommended
    for (NSString *preferredLocale in preferredLocales) {
        for (NSString *related in [GlossaryDatabase relatedDatabaseForLocale:preferredLocale withPlatform:self.selectedPlatform]) {
            if (![downloadedLocales containsObject:related]) {
                [relatedLocales addObject:related];
            }
        }
    }
    self.relatedLocales = [relatedLocales array];

    NSMutableArray *otherLocales = [NSMutableArray array];
    for (NSString *locale in allLocales) {
        if (![downloadedLocales containsObject:locale] && ![relatedLocales containsObject:locale]) {
            [otherLocales addObject:locale];
        }
    }
    self.otherAvailableLocales = otherLocales;
    [self.outlineView reloadData];
    [self.outlineView expandItem:nil expandChildren:YES];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (!item) {
        NSInteger count = 0;
        if (self.relatedLocales.count) count++;
        if (self.otherAvailableLocales.count) count++;
        return count;
    }
    if (item == self.relatedLocales) {
        return self.relatedLocales.count;
    } else if (item == self.otherAvailableLocales) {
        return self.otherAvailableLocales.count;
    }
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return (item == self.relatedLocales || item == self.otherAvailableLocales);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        if (index == 0 && self.relatedLocales.count) {
            return self.relatedLocales;
        }
        if ((index == 1 && self.otherAvailableLocales) || (index == 0 && !self.relatedLocales.count)) {
            return self.otherAvailableLocales;
        }
    }
    if (item == self.relatedLocales) {
        return self.relatedLocales[index];
    } else if (item == self.otherAvailableLocales) {
        return self.otherAvailableLocales[index];
    }
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if ([tableColumn.identifier isEqual:@"name"]) {
        if (item == self.relatedLocales) {
            return NSLocalizedString(@"Recommended Locales", @"");
        } else if (item == self.otherAvailableLocales) {
            if (self.relatedLocales.count) {
                return NSLocalizedString(@"Other", @"");
            } else {
                return NSLocalizedString(@"All", @"");
            }
        } else if ([item isKindOfClass:[NSString class]]) {
            return item;
        }
    }
    if ([tableColumn.identifier isEqual:@"check"]) {
        if ([item isKindOfClass:[NSString class]]) {
            return @([self.selectedLocales containsObject:item]);
        }
        if ([item isKindOfClass:[NSArray class]]) {
            return @([[NSSet setWithArray:item] isSubsetOfSet:self.selectedLocales]);
        }
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if ([tableColumn.identifier isEqual:@"check"] && [object isKindOfClass:[NSNumber class]]) {
        if ([item isKindOfClass:[NSString class]]) {
            if ([object boolValue]) {
                [self.selectedLocales addObject:item];
            } else {
                [self.selectedLocales removeObject:item];
            }
        } else if ([item isKindOfClass:[NSArray class]]) {
            for (NSString *locale in (NSArray*)item) {
                if ([object boolValue]) {
                    [self.selectedLocales addObject:locale];
                } else {
                    [self.selectedLocales removeObject:locale];
                }
            }
            [self.outlineView reloadData];
        }
    }
}

- (IBAction)platformSegmentClicked:(id)sender {
    self.selectedPlatform = self.platformSegment.selectedSegment == 0 ? GlossaryPlatformIOS : self.platformSegment.selectedSegment == 1 ? GlossaryPlatformMac : GlossaryPlatformAny;
    [self calculateLocales];
}

- (IBAction)downloadClicked:(id)sender {
    [self.downloadButton setTitle:NSLocalizedString(@"Downloading...", @"")];
    [self.progressIndicator setHidden:NO];
    self.outlineView.enabled = self.downloadButton.enabled = self.platformSegment.enabled = NO;
    self.localesDownloadQueue = [NSMutableArray arrayWithCapacity:self.selectedLocales.count];
    for (NSString *selectedLocale in self.selectedLocales) {
        [self.localesDownloadQueue addObject:selectedLocale];
    }
    NSProgress *mainProgress = [NSProgress progressWithTotalUnitCount:self.selectedLocales.count];
    self.progress = mainProgress;
    [mainProgress addObserver:self
                   forKeyPath:@"fractionCompleted"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    [self kickDownloadQueue];
}

- (void)kickDownloadQueue {
    if (!self.localesDownloadQueue.count) {
        return;
    }
    NSString *locale = [self.localesDownloadQueue firstObject];
    [self.localesDownloadQueue removeObjectAtIndex:0];
    GlossaryDatabase *db = [GlossaryDatabase databaseWithPlatform:self.selectedPlatform locale:locale];
    self.downloadingDatabase = db;
    __weak typeof(self) _self = self;
    [self.progress becomeCurrentWithPendingUnitCount:1];
    [db download:^(NSError * _Nonnull error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (error && error.code != -999) {
                [[NSAlert alertWithError:error] runModal];
                [_self.window.sheetParent endSheet:_self.window
                                        returnCode:NSModalResponseCancel];
                return;
            }
            [self.progress resignCurrent];
            if (_self.localesDownloadQueue.count) {
                [_self kickDownloadQueue];
            } else {
                [_self.window.sheetParent endSheet:_self.window returnCode:NSModalResponseOK];
            }
        });
    }];
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
    [self.localesDownloadQueue removeAllObjects];
    [self.window.sheetParent endSheet:self.window
                           returnCode:NSModalResponseCancel];
}

@end
