//
//  XclocDocument.m
//  Xliffie
//
//  Created by Brian Chan on 2019/02/21.
//  Copyright © 2019 b123400. All rights reserved.
//

#import "XclocDocument.h"

@interface XclocDocument ()

@property (nonatomic, strong) NSFileWrapper *fileWrapper;
@property (nonatomic, strong) NSFileWrapper *xliffParentFileWrapper;
@property (nonatomic, strong) NSFileWrapper *xliffFileWrapper;
@property (nonatomic, strong) NSFileWrapper *sourceContentsFileWrapper;

@end

@implementation XclocDocument

- (id)copyWithZone:(NSZone *)zone {
    XclocDocument *newDocument = [super copyWithZone:zone];
    newDocument.fileWrapper = self.fileWrapper;
    newDocument.xliffParentFileWrapper = self.xliffParentFileWrapper;
    newDocument.xliffFileWrapper = self.xliffFileWrapper;
    return newDocument;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError * _Nullable *)outError {
    if (![fileWrapper isDirectory] || ![[[[fileWrapper filename] pathExtension] lowercaseString] isEqualToString:@"xcloc"]) {
        return NO;
    }

    NSDictionary<NSString *, NSFileWrapper *> *fileWrappers = [fileWrapper fileWrappers];
    NSFileWrapper *localisedContents = fileWrappers[@"Localized Contents"];
    if (![localisedContents isDirectory]) {
        return NO;
    }
    self.sourceContentsFileWrapper = fileWrappers[@"Source Contents"];
    NSDictionary<NSString *, NSFileWrapper *> *localisedContentsDict = [localisedContents fileWrappers];
    for (NSString *filename in localisedContentsDict) {
        NSFileWrapper *xliffFileWrapper = localisedContentsDict[filename];
        if ([xliffFileWrapper isRegularFile] && [Document isXliffExtension: [filename pathExtension]]) {
            self.fileWrapper = fileWrapper;
            self.xliffParentFileWrapper = localisedContents;
            self.xliffFileWrapper = xliffFileWrapper;

            NSData *xmlData = [xliffFileWrapper regularFileContents];
            [self readFromData:xmlData ofType:typeName error:outError];
            return YES;
        }
    }
    
    return NO;
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
    NSData *data = [self dataOfType:typeName error:outError];
    NSFileWrapper *oldFileWrapper = self.xliffFileWrapper;
    NSFileWrapper *newFileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:data];
    [newFileWrapper setPreferredFilename:oldFileWrapper.filename];
    [newFileWrapper setFilename:oldFileWrapper.filename];
    
    [self.xliffParentFileWrapper removeFileWrapper:oldFileWrapper];
    [self.xliffParentFileWrapper addFileWrapper:newFileWrapper];
    self.xliffFileWrapper = newFileWrapper;

    return self.fileWrapper;
}

- (NSFileWrapper *)sourceContentAtPath:(NSString *)path {
    if (![self.sourceContentsFileWrapper isDirectory]) return nil;
    NSArray<NSString *> *pathComponents = [path pathComponents];
    NSFileWrapper *currentWrapper = self.sourceContentsFileWrapper;
    for (NSString *p in pathComponents) {
        NSDictionary<NSString*, NSFileWrapper *> *folderContent = [currentWrapper fileWrappers];
        currentWrapper = folderContent[p];
    }
    return currentWrapper;
}

- (GlossaryPlatform)findPlatformFromUIFile:(NSFileWrapper *)fileWrapper {
    if (![fileWrapper isRegularFile]) return GlossaryPlatformAny;
    NSString *extension = [[fileWrapper filename] pathExtension];
    if (![extension.lowercaseString isEqual:@"storyboard"] && ![extension.lowercaseString isEqual:@"xib"]) return GlossaryPlatformAny;
    NSData *data = [fileWrapper regularFileContents];
    NSError *error = nil;
    NSXMLDocument *doc = [[NSXMLDocument alloc] initWithData:data options:0 error:&error];
    if (error) {
        NSLog(@"Cannot read file as xml %@", error);
        return GlossaryPlatformAny;
    }
    NSString *runtime = [[[doc rootElement] attributeForName:@"targetRuntime"] stringValue];
    if ([runtime isEqual:@"MacOSX.Cocoa"]) return GlossaryPlatformMac;
    if ([runtime isEqual:@"iOS.CocoaTouch"]) return GlossaryPlatformIOS;
    return GlossaryPlatformAny;
}

- (GlossaryPlatform)glossaryPlatformWithSourcePath:(NSString *)pathInSourceContents {
    NSFileWrapper *file = [self sourceContentAtPath:pathInSourceContents];
    return [self findPlatformFromUIFile:file];
}

- (GlossaryPlatform)findAnyGlossaryPlatformInFileWrapper:(NSFileWrapper*)wrapper {
    if (!wrapper) {
        wrapper = self.sourceContentsFileWrapper;
    }
    if ([wrapper isRegularFile]) {
        GlossaryPlatform platform = [self findPlatformFromUIFile:wrapper];
        if (platform != GlossaryPlatformAny) {
            return platform;
        }
    } else if ([wrapper isDirectory]) {
        NSDictionary<NSString*, NSFileWrapper*> *folderContent = [wrapper fileWrappers];
        for (NSString *name in folderContent) {
            NSFileWrapper *item = folderContent[name];
            GlossaryPlatform platform = [self findAnyGlossaryPlatformInFileWrapper:item];
            if (platform != GlossaryPlatformAny) {
                return platform;
            }
        }
    }
    return GlossaryPlatformAny;
}

+ (BOOL)isXclocExtension:(NSString *)extension {
    return [[extension lowercaseString] isEqualToString:@"xcloc"];
}

@end
