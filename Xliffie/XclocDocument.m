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

@end

@implementation XclocDocument

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError * _Nullable *)outError {
    if (![fileWrapper isDirectory] || ![[[[fileWrapper filename] pathExtension] lowercaseString] isEqualToString:@"xcloc"]) {
        return NO;
    }

    NSDictionary<NSString *, NSFileWrapper *> *fileWrappers = [fileWrapper fileWrappers];
    NSFileWrapper *localisedContents = fileWrappers[@"Localized Contents"];
    if (![localisedContents isDirectory]) {
        return NO;
    }
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

+ (BOOL)isXclocExtension:(NSString *)extension {
    return [[extension lowercaseString] isEqualToString:@"xcloc"];
}

@end
