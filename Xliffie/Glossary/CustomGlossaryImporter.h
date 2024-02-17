//
//  CustomGlossaryImporter.h
//  Xliffie
//
//  Created by b123400 on 2024/02/17.
//  Copyright © 2024 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomGlossaryRow.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CustomGlossaryImporterDelegate <NSObject>

- (void)didReadRow:(CustomGlossaryRow *)row fromImporter:(id)importer;

@end

@interface CustomGlossaryImporter : NSObject

@property (nonatomic, weak) id <CustomGlossaryImporterDelegate> delegate;

- (void)importFromFile:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
