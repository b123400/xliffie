//
//  TargetMissingViewController.m
//  Xliffie
//
//  Created by b123400 on 18/12/2015.
//  Copyright © 2015 b123400. All rights reserved.
//

#import "TargetMissingViewController.h"
#import "File.h"

@interface TargetMissingViewController ()
@property (weak) IBOutlet NSPopUpButton *sourceButton;
@property (weak) IBOutlet NSPopUpButton *targetButton;

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
        [sourceTitles addObject:file.sourceLanguage];
    }
    
    NSMutableArray *targetLanguages = [[NSMutableArray alloc] init];
    for (NSString *locale in [NSLocale availableLocaleIdentifiers]) {
        [targetLanguages addObject: [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                                          value:locale]];
    }
    [targetLanguages sortUsingSelector:@selector(compare:)];
    
    // preferred language in systems, more likely to be selected, so put to top
    for (NSString *preferredLangaugeIdentifier in [[NSLocale preferredLanguages] reverseObjectEnumerator]) {
        NSString *preferredLanguage = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                                            value:preferredLangaugeIdentifier];
        NSUInteger index = [targetLanguages indexOfObject:preferredLanguage];
        if (index != NSNotFound) {
            [targetLanguages removeObjectAtIndex:index];
        }
        [targetLanguages insertObject:preferredLanguage atIndex:0];
    }
    
    [targetLanguages removeObject:self.document.files[0].sourceLanguage];
    
    [self.sourceButton addItemsWithTitles:[sourceTitles array]];
    [self.targetButton addItemsWithTitles:targetLanguages];
}

- (void)setDocument:(Document *)document {
    _document = document;
    [self configureView];
}

- (IBAction)okClicked:(id)sender {
    for (File *file in self.document.files) {
        file.targetLanguage = [self.targetButton titleOfSelectedItem];
    }
    [self.delegate targetMissingViewController:self
                          didSetTargetLanguage:[self.targetButton titleOfSelectedItem]];
}

@end
