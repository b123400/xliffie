//
//  TargetMissingViewController.m
//  Xliffie
//
//  Created by b123400 on 18/12/2015.
//  Copyright © 2015 b123400. All rights reserved.
//

#import "TargetMissingViewController.h"
#import "File.h"

@interface LanguageSet : NSObject
// language code, not name
@property NSString *mainLanguage;
@property NSMutableArray <NSString*> *subLanguages;
@end

@implementation LanguageSet
- (id)init {
    self = [super init];
    self.subLanguages = [NSMutableArray array];
    return self;
}
@end

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
    self.okButton.enabled = NO;
}

- (void)configureView {
    [self.sourceButton removeAllItems];
    [self.targetButton removeAllItems];
    
    NSMutableOrderedSet *sourceTitles = [NSMutableOrderedSet orderedSet];
    for (File *file in self.document.files) {
        [sourceTitles addObject:[[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                                      value:file.sourceLanguage]];
    }
    
    [self.sourceButton addItemsWithTitles:[sourceTitles array]];
    
    NSMutableArray <LanguageSet*> *targetLanguages = [[NSMutableArray alloc] init];
    
    for (NSString *localeIdentifier in [[NSLocale availableLocaleIdentifiers] sortedArrayUsingSelector:@selector(compare:)]) {
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:localeIdentifier];
        NSString *thisLanguageCode = [locale objectForKey:NSLocaleLanguageCode];
        NSString *thisLanguageScript = [locale objectForKey:NSLocaleScriptCode];
        
        LanguageSet *lastLanguageSet = [targetLanguages lastObject];
        NSString *lastLanguageIdentifier = [lastLanguageSet mainLanguage];
        NSLocale *lastLocale = [NSLocale localeWithLocaleIdentifier:lastLanguageIdentifier];
        NSString *lastLanguageCode = [lastLocale objectForKey:NSLocaleLanguageCode];
        NSString *lastLanguageScript = [lastLocale objectForKey:NSLocaleScriptCode];
        
        if (![lastLanguageCode isEqualToString:thisLanguageCode] ||
            ([lastLanguageCode isEqualToString:thisLanguageCode] &&
             thisLanguageScript &&
             ![lastLanguageScript isEqualToString:thisLanguageScript])) {
            
            // make new language set
            LanguageSet *thisLanguageSet = [[LanguageSet alloc] init];
            thisLanguageSet.mainLanguage = localeIdentifier;
            [targetLanguages addObject:thisLanguageSet];
            
        } else {
            // this code is same as last code, means this is a sub-language of the last one
            // like: zh_Hant -> zh_Hang_HK
            [lastLanguageSet.subLanguages addObject:localeIdentifier];
        }

//        [targetLanguages addObject: [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
//                                                                          value:localeIdentifier]];
    }
    [targetLanguages sortUsingComparator:^NSComparisonResult(LanguageSet *obj1, LanguageSet *obj2) {
        NSString *displayName1 = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                                       value:obj1.mainLanguage];
        NSString *displayName2 = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                                       value:obj2.mainLanguage];
        return [displayName1 compare:displayName2];
    }];
    
    for (LanguageSet *languageSet in targetLanguages) {
        NSString *languageName = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                                       value:languageSet.mainLanguage];
        NSMenuItem *thisItem = [[NSMenuItem alloc] initWithTitle:languageName
                                                          action:@selector(selectedTargetItem:)
                                                   keyEquivalent:@""];
        thisItem.target = self;
        thisItem.representedObject = languageSet.mainLanguage;
        
        if (languageSet.subLanguages.count) {
            // one more same item in sub menu
            NSMenu *subMenu = [[NSMenu alloc] init];
            [thisItem setSubmenu:subMenu];
            NSMenuItem *subItem = [[NSMenuItem alloc] initWithTitle:languageName
                                                              action:@selector(selectedTargetItem:)
                                                       keyEquivalent:@""];
            thisItem.target = self;
            thisItem.representedObject = languageSet.mainLanguage;
            [subMenu addItem:subItem];
            
            // all sub languages
            for (NSString *subLanguage in languageSet.subLanguages) {
                NSString *subLanguageName = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                                                  value:subLanguage];
                NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:subLanguageName
                                                              action:@selector(selectedTargetItem:)
                                                       keyEquivalent:@""];
                item.representedObject = subLanguage;
                [subMenu addItem:item];
            }
        }
        
        [[self.targetButton menu] addItem:thisItem];
    }
    
    // preferred language in systems
    if ([[NSLocale preferredLanguages] count] > 0) {
        [[self.targetButton menu] insertItem:[NSMenuItem separatorItem] atIndex:0];
        // more likely to be selected, so put to top
        for (NSString *preferredLangaugeIdentifier in [[NSLocale preferredLanguages] reverseObjectEnumerator]) {
            NSString *preferredLanguage = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                                                value:preferredLangaugeIdentifier];
            
            NSMenuItem *menuItem = [[self.targetButton menu] insertItemWithTitle:preferredLanguage
                                                                          action:@selector(selectedTargetItem:)
                                                                   keyEquivalent:@""
                                                                         atIndex:0];
            menuItem.representedObject = preferredLangaugeIdentifier;
        }
    }
    [self.targetButton setTitle:@"Choose language here"];
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
