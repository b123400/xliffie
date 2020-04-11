//
//  DocumentListViewController.h
//  Xliffie
//
//  Created by b123400 on 2020/04/11.
//  Copyright © 2020 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DocumentListViewControllerDelegate

- (NSArray<NSDocument *> *)documentsForListController:(id)sender;
- (void)listController:(id)sender didSelectedDocumentAtIndex:(NSUInteger)index;

@end

@interface DocumentListViewController : NSViewController<NSTableViewDelegate, NSTableViewDataSource>

@property (weak) id<DocumentListViewControllerDelegate> delegate;
@property (weak) IBOutlet NSTableView *tableView;

- (void)reloadData;
- (void)selectDocumentAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
