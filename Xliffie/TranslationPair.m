//
//  TranslationPair.m
//  Xliffie
//
//  Created by b123400 on 6/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "TranslationPair.h"
#import <AppKit/AppKit.h>
#import "Glossary.h"

@interface TranslationPair ()

@property (nonatomic, strong) NSXMLElement *xmlElement;
@property (nonatomic, strong) NSArray <NSString*> *cachedTargetWarnings;

@end

@implementation TranslationPair

- (instancetype)initWithXMLElement:(NSXMLElement*)element {
    self = [super init];
    
    self.xmlElement = element;
    
    _source = [[[element elementsForName:@"source"] firstObject] stringValue];
    // Don't use setter so we don't trigger state update
    _target = [self.targetElement stringValue];
    _note = [[[element elementsForName:@"note"] firstObject] stringValue];
    
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    TranslationPair *tp = [[TranslationPair allocWithZone:zone] initWithXMLElement:self.xmlElement];
    tp.alternativePair = self.alternativePair;
    tp.file = self.file;
    return tp;
}

- (NSString*)sourceForDisplay {
    if (self.alternativePair && self.alternativePair.isTranslated) {
        return self.alternativePair.target ?: @"";
    }
    return _source;
}

- (void)setSource:(NSString *)source {
    self.cachedTargetWarnings = nil;
    NSXMLElement *sourceElement = [[self.xmlElement elementsForName:@"source"] firstObject];
    if (!sourceElement) {
        sourceElement = [NSXMLElement elementWithName:@"source"];
        [self.xmlElement addChild:sourceElement];
    }
    [sourceElement setStringValue:source];
    _source = source;
}

- (NSXMLElement*)targetElement {
    return [[self.xmlElement elementsForName:@"target"] firstObject];
}

- (void)setTarget:(NSString *)target {
    self.cachedTargetWarnings = nil;
    NSXMLElement *targetElement = self.targetElement;
    
    if (!target) {
        if (!targetElement) return;
        
        NSUInteger index = [[self.xmlElement children] indexOfObject:targetElement];
        [self.xmlElement removeChildAtIndex:index];
        return;
    }
    if (!targetElement && target) {
        targetElement = [NSXMLElement elementWithName:@"target"];
        [self.xmlElement addChild:targetElement];
    }
    
    TranslationPairState state = [self state];
    NSDocument *document = (NSDocument*)[self.file document];
    if (self.xmlElement &&         // setting target after initialization
        document.hasUndoManager) { // can undo
        
        NSUndoManager *manager = [document undoManager];
        [manager registerUndoWithTarget:self
                               selector:@selector(setTarget:)
                                 object:self.target];
        if (state == TranslationPairStateMarkedAsTranslated) {
            [manager registerUndoWithTarget:self
                                   selector:@selector(markAsTranslated)
                                     object:nil];
        } else if (state == TranslationPairStateMarkedAsNotTranslated) {
            [manager registerUndoWithTarget:self
                                   selector:@selector(markAsNotTranslated)
                                     object:nil];
        }
    }
    
    [targetElement setStringValue:target];
    _target = target;
    [self unmark];
}

- (NSString *)targetState {
    return [[[self targetElement] attributeForName:@"state"] stringValue];
}

- (void)setTargetState:(NSString *)targetState {
    if (![self targetElement]) {
        [self setTarget:@""];
    }
    NSXMLNode *attr = [NSXMLNode attributeWithName:@"state"
                                       stringValue:targetState];
    [[self targetElement] addAttribute:attr];
}

- (TranslationPairState)stateFromContent {
    if (![self.target length]) {
        return TranslationPairStateEmpty;
    }
    if ([self.source isEqualTo:self.target]) {
        Glossary *glossary = [Glossary sharedGlossaryWithLocale:self.file.targetLanguage];
        BOOL isMenu = [self.file.original.lastPathComponent.lowercaseString containsString:@"menu"];
        NSString *glossaryTranslation = [glossary translate:self.source isMenu:isMenu];
        if ([glossaryTranslation isEqualTo:self.target]) {
            return TranslationPairStateTranslated;
        }
        return TranslationPairStateSame;
    }
    if ([self warningsForTarget].count) {
        return TranslationPairStateTranslatedWithWarnings;
    }
    return TranslationPairStateTranslated;
}

- (TranslationPairState)state {
    NSString *targetState = self.targetState;
    NSArray<NSString *> *translatedStates = @[@"signed-off", @"translated", @"final"];
    NSArray<NSString *> *notTranslatedStates = @[
        @"needs-adaptation",
        @"needs-l10n",
        @"needs-review-adaptation",
        @"needs-review-l10n",
        @"needs-review-translation",
        @"needs-translation",
        @"new"
    ];
    if ([translatedStates containsObject:targetState]) {
        return TranslationPairStateMarkedAsTranslated;
    }
    if ([notTranslatedStates containsObject:targetState]) {
        return TranslationPairStateMarkedAsNotTranslated;
    }
    return [self stateFromContent];
}

- (void)unmark {
    [[self targetElement] removeAttributeForName:@"state"];
}

- (void)markAsTranslated {
    TranslationPairState state = [self state];
    self.targetState = @"translated";
    
    NSDocument *document = (NSDocument*)[self.file document];
    if (self.xmlElement &&         // setting target after initialization
        document.hasUndoManager) { // can undo
        
        NSUndoManager *manager = [document undoManager];
        if (state == TranslationPairStateMarkedAsNotTranslated) {
            [manager registerUndoWithTarget:self
                                   selector:@selector(markAsNotTranslated)
                                     object:nil];
        } else {
            [manager registerUndoWithTarget:self
                                   selector:@selector(unmark)
                                     object:nil];
        }
    }
}

- (void)markAsNotTranslated {
    TranslationPairState state = [self state];
    self.targetState = @"needs-translation";
    
    NSDocument *document = (NSDocument*)[self.file document];
    if (self.xmlElement &&         // setting target after initialization
        document.hasUndoManager) { // can undo
        
        NSUndoManager *manager = [document undoManager];
        if (state == TranslationPairStateMarkedAsTranslated) {
            [manager registerUndoWithTarget:self
                                   selector:@selector(markAsTranslated)
                                     object:nil];
        } else {
            [manager registerUndoWithTarget:self
                                   selector:@selector(unmark)
                                     object:nil];
        }
    }
}

- (BOOL)isTranslated {
    switch (self.state) {
        case TranslationPairStateTranslated:
        case TranslationPairStateMarkedAsTranslated:
            return YES;
        case TranslationPairStateMarkedAsNotTranslated:
        case TranslationPairStateEmpty:
        case TranslationPairStateSame:
        case TranslationPairStateTranslatedWithWarnings:
            return NO;
    }
    return YES;
}

- (NSArray <NSString*> *)warningsForTarget {
    if (!self.cachedTargetWarnings) {
        if (self.target) {
            self.cachedTargetWarnings = [self formatWarningsForProposedTranslation:self.target];
        } else {
            self.cachedTargetWarnings = @[];
        }
    }
    return self.cachedTargetWarnings;
}

- (BOOL)matchSearchFilter:(NSString*)filter {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:filter options:NSRegularExpressionCaseInsensitive error:&error];
    if (regex && !error) {
        if (self.source && [regex numberOfMatchesInString:self.source options:0 range:NSMakeRange(0, self.source.length)] >= 1) {
            return YES;
        }
        if (self.target && [regex numberOfMatchesInString:self.target options:0 range:NSMakeRange(0, self.target.length)] >= 1) {
            return YES;
        }
        if (self.note && [regex numberOfMatchesInString:self.note options:0 range:NSMakeRange(0, self.note.length)] >= 1) {
            return YES;
        }
    }
    
    filter = filter.lowercaseString;
    
    return [self.source.lowercaseString containsString:filter] ||
        [self.target.lowercaseString containsString:filter] ||
        [self.note.lowercaseString containsString:filter];
}

- (NSArray*)formatWarningsForProposedTranslation:(NSString*)newTranslation {
    NSDictionary *thatFormats = [self formatSpecifiersInString:newTranslation];
    NSDictionary *thisFormats = [self formatSpecifiersInString:self.source];
    NSMutableArray *warnings = [NSMutableArray array];
    for (NSString *key in thisFormats) {
        NSNumber *thatCount = [thatFormats objectForKey:key];
        if (!thatCount) {
            [warnings addObject:[NSString stringWithFormat:NSLocalizedString(@"The source contains at least one \"%%%@\", but your input doesn\'t",nil), key]];
            continue;
        }
        NSNumber *thisCount = [thisFormats objectForKey:key];
        if (![thisCount isEqualTo:thatCount]) {
            [warnings addObject:[NSString stringWithFormat:NSLocalizedString(@"The source contains %@ \"%%%@\", but your input contains %@",nil), thisCount, key, thatCount]];
            continue;
        }
    }
    for (NSString *key in thatFormats) {
        if (![thisFormats objectForKey:key]) {
            [warnings addObject:[NSString stringWithFormat:NSLocalizedString(@"The source doesn\'t contain \"%%%@\", but your input does",nil), key]];
        }
    }
    return warnings;
}

- (NSDictionary*)formatSpecifiersInString:(NSString*)input {
    NSString *pattern = @"%(?:([0-9])\\$)?(?:[0-9]?.[0-9])?((?:h|hh|l|ll|q|L|z|t|j)?[@dDuUxXoOfeEgGcCsSpaAF])";
    NSError *error = nil;
    
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    [regex enumerateMatchesInString:input options:0 range:NSMakeRange(0, input.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        
        NSRange typeRange = [result rangeAtIndex:2];
        NSString *typeString = [input substringWithRange:typeRange];
        if (![resultDict objectForKey:typeString]) {
            [resultDict setObject:@0 forKey:typeString];
        }
        [resultDict setObject:@([resultDict[typeString] integerValue]+1) forKey:typeString];
    }];
    return resultDict;
}

@end
