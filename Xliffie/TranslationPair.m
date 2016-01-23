//
//  TranslationPair.m
//  Xliffie
//
//  Created by b123400 on 6/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "TranslationPair.h"
#import <AppKit/AppKit.h>

@interface TranslationPair ()

@property (nonatomic, strong) NSXMLElement *xmlElement;
@property (nonatomic, strong) NSArray <NSString*> *cachedTargetWarnings;

@end

@implementation TranslationPair

- (instancetype)initWithXMLElement:(NSXMLElement*)element {
    self = [super init];
    
    self.xmlElement = element;
    
    self.source = [[[element elementsForName:@"source"] firstObject] stringValue];
    self.target = [[[element elementsForName:@"target"] firstObject] stringValue];
    self.note = [[[element elementsForName:@"note"] firstObject] stringValue];
    
    return self;
}

- (NSString*)sourceForDisplay {
    if (self.alternativePair &&
        self.alternativePair.target &&
        ![self.alternativePair.target isEqualToString:@""]) {
        return self.alternativePair.target;
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

- (void)setTarget:(NSString *)target {
    self.cachedTargetWarnings = nil;
    NSXMLElement *targetElement = [[self.xmlElement elementsForName:@"target"] firstObject];
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
    
    NSDocument *document = (NSDocument*)[self.file document];
    if (self.xmlElement &&         // setting target after initialization
        document.hasUndoManager) { // can undo
        
        NSUndoManager *manager = [document undoManager];
        [manager registerUndoWithTarget:self
                               selector:@selector(setTarget:)
                                 object:self.target];
    }
    
    [targetElement setStringValue:target];
    _target = target;
}

- (NSArray <NSString*> *)warningsForTarget {
    if (!self.cachedTargetWarnings) {
        self.cachedTargetWarnings = [self formatWarningsForProposedTranslation:self.target];
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
        
//        NSRange indexRange = [result rangeAtIndex:1];
        NSRange typeRange = [result rangeAtIndex:2];
        
//        NSInteger index = -1;
//        if (indexRange.location != NSNotFound) {
//            index = [[input substringWithRange:indexRange] integerValue];
//        }
        NSString *typeString = [input substringWithRange:typeRange];
        if (![resultDict objectForKey:typeString]) {
            [resultDict setObject:@0 forKey:typeString];
        }
        [resultDict setObject:@([resultDict[typeString] integerValue]+1) forKey:typeString];
    }];
    return resultDict;
}

@end
