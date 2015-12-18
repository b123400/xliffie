//
//  TargetMissingViewController.h
//  Xliffie
//
//  Created by b123400 on 18/12/2015.
//  Copyright © 2015 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"

@protocol TargetMissingViewController <NSObject>

- (void)targetMissingViewController:(id)sender didSetTargetLanguage:(NSString*)targetLanguage;

@end

@interface TargetMissingViewController : NSViewController

@property (nonatomic, strong) Document *document;
@property (nonatomic, weak) id <TargetMissingViewController> delegate;

@end
