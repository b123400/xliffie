//
//  TranslationUnitGroup.m
//  Xliffie
//
//  Created by b123400 on 2023/10/25.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "TranslationPairGroup.h"
#import "BRTextAttachmentCell.h"
#import "Utilities/Utilities.h"

@implementation TranslationPairGroup

/// Array of Either<TranslationPair | TranslationPairGroup>
+ (NSArray*)groupsWithTranslationPairs:(NSArray<TranslationPair*>*)pairs {
    NSMutableArray<TranslationPairGroup*> *results = [NSMutableArray array];
    
    for (TranslationPair *pair in pairs) {
        NSArray<NSArray<NSString *>*> *modifiers = [pair transUnitModifiers];
        if (![modifiers count]) {
            [results addObject:[[TranslationPairGroup alloc] initWithMainPair:pair]];
            continue;
        }
        TranslationPairGroup *lastGroup = [results lastObject];
        if (![lastGroup tryAddPair:pair]) {
            TranslationPairGroup *group = [[TranslationPairGroup alloc] initWithChild:pair];
            [results addObject:group];
        }
    }
    for (TranslationPairGroup *rootGroup in results) {
        NSMutableArray *newChildren = [NSMutableArray array];
        for (TranslationPairGroup *group in rootGroup.children) {
            if ([group.pathName isEqual:@"device"]) {
                for (TranslationPairGroup *groupChild in group.children) {
                    groupChild.groupModifierKey = group.pathName;
                }
                [newChildren addObjectsFromArray:group.children];
            } else if ([group.pathName isEqual:@"substitutions"]) {
                for (TranslationPairGroup *groupChild in group.children) {
                    groupChild.groupModifierKey = group.pathName;
                }
                [newChildren addObjectsFromArray:group.children];
            } else {
                [newChildren addObject:group];
            }
        }
        rootGroup.children = newChildren;
    }
    return [TranslationPairGroup flattened:results];
}

+ (NSMutableArray *)flattened:(NSArray<TranslationPairGroup *> *)groups {
    NSMutableArray *results = [NSMutableArray array];
    for (TranslationPairGroup *group in groups) {
        [group removePluralLevel];
        if (group.mainPair && !group.children.count) {
            [results addObject:group.mainPair];
            continue;
        }
        group.children = [TranslationPairGroup flattened:group.children];
        [results addObject:group];
    }
    return results;
}

- (BOOL)removePluralLevel {
    if (self.children.count == 1 && [[self.children.firstObject pathName] isEqual:@"plural"]) {
        self.children = (NSMutableArray *)[[self.children firstObject] children];
        return YES;
    } else {
        for (TranslationPairGroup *group in self.children) {
            if ([group removePluralLevel]) return YES;
        }
    }
    return NO;
}

- (instancetype)initWithPathName:(NSString *)pathName {
    if (self = [super init]) {
        self.children = [NSMutableArray array];
        self.groupModifierKey = nil;
        self.pathName = pathName;
    }
    return self;
}

- (instancetype)initWithMainPair:(TranslationPair *)pair {
    if (self = [super init]) {
        self.children = [NSMutableArray array];
        self.groupModifierKey = nil;
        self.mainPair = pair;
    }
    return self;
}

- (instancetype)initWithChild:(TranslationPair *)pair {
    if (self = [super init]) {
        self.children = [NSMutableArray array];
        self.groupModifierKey = nil;
        TranslationPairGroup *child = [self ensureChildPath:[pair transUnitModifierPath]];
        child.mainPair = pair;
    }
    return self;
}

- (TranslationPairGroup *)ensureChildPath:(NSArray<NSString*> *)path {
    if ([path count] == 0) {
        return self;
    }
    NSString *currentName = [path firstObject];
    NSArray *rest = [path subarrayWithRange:NSMakeRange(1, path.count - 1)];
    for (TranslationPairGroup *group in self.children) {
        if ([group.pathName isEqual:currentName]) {
            return [group ensureChildPath:rest];
        }
    }
    TranslationPairGroup *newGroup = [[TranslationPairGroup alloc] initWithPathName:currentName];
    [self.children addObject:newGroup];
    return [newGroup ensureChildPath:rest];
}

- (BOOL)tryAddPair:(TranslationPair *)pair {
    if (![pair.transUnitIdWithoutModifiers isEqual:self.transUnitIdWithoutModifiers]) {
        return NO;
    }
    TranslationPairGroup *group = [self ensureChildPath:[pair transUnitModifierPath]];
    group.mainPair = pair;
    return YES;
}

- (NSString *)transUnitIdWithoutModifiers {
    if (self.mainPair) {
        return self.mainPair.transUnitIdWithoutModifiers;
    }
    for (TranslationPairGroup *child in self.children) {
        NSString *tuId = [child transUnitIdWithoutModifiers];
        if (tuId) return tuId;
    }
    return nil;
}

- (id)stringForSourceColumn {
    if ([self.groupModifierKey isEqual:@"substitutions"]) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        BRTextAttachmentCell *cell = [[BRTextAttachmentCell alloc] initTextCell:self.pathName];
        cell.backgroundColor = [NSColor systemPurpleColor];
        attachment.attachmentCell = cell;
        return [NSAttributedString attributedStringWithAttachment:attachment];
    } else if ([self.groupModifierKey isEqual:@"device"]) {
        NSString *s = [Utilities stringForDevice:self.pathName];
        if (s) return s;
    }
    return [self.mainPair sourceForDisplayWithFormatSpecifierReplaced] ?: self.pathName ?: [self transUnitIdWithoutModifiers];
}

@end
