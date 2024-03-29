//
//  TranslationPair.h
//  Xliffie
//
//  Created by b123400 on 6/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "File.h"

typedef enum : NSUInteger {
    TranslationPairStateMarkedAsNotTranslated = 1,
    TranslationPairStateEmpty = 1 << 1,
    TranslationPairStateSame = 1 << 2,
    TranslationPairStateTranslatedWithWarnings = 1 << 3,
    TranslationPairStateTranslated = 1 << 4,
    TranslationPairStateMarkedAsTranslated = 1 << 5,
} TranslationPairState;

@interface TranslationPair : NSObject<NSCopying>

@property (nonatomic, strong) NSXMLElement *xmlElement;

@property (nonatomic, strong) NSString *source;
@property (nonatomic, strong) NSString *target;
@property (nonatomic, strong) NSString *note;

@property (nonatomic) NSString *targetState;
@property (nonatomic) TranslationPairState state;
@property (nonatomic, readonly) BOOL isTranslated;

@property (nonatomic, strong) TranslationPair *alternativePair; // map another langauge

@property (nonatomic, weak) File *file;

- (instancetype)initWithXMLElement:(NSXMLElement*)element;

- (BOOL)matchSearchFilter:(NSString*)filter;
- (NSArray*)warningsForProposedTranslation:(NSString*)newTranslation;

- (NSString*)sourceForDisplay;
- (NSString*)plainSourceForDisplayWithModifier;
- (NSArray <NSString*> *)warningsForTarget;

- (void)markAsTranslated;
- (void)markAsNotTranslated;
- (void)unmark;

- (void)setAttributedTarget:(NSAttributedString *)attrStr;
- (NSAttributedString *)sourceForDisplayWithFormatSpecifierReplaced;
- (NSAttributedString *)targetWithFormatSpecifierReplaced;
+ (NSAttributedString *)stringWithFormatSpecifiersReplaced:(NSString *)input;

- (NSString *)transUnitIdWithoutModifiers;
- (NSArray<NSArray<NSString*>*> *)transUnitModifiers;
- (NSArray<NSString*> *)transUnitModifierPath;
- (NSDictionary *)transUnitModifiersDict;

@end
