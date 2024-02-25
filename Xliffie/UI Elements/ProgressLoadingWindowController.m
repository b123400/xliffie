//
//  ProgressLoadingWindowController.m
//  Xliffie
//
//  Created by b123400 on 2024/02/25.
//  Copyright © 2024 b123400. All rights reserved.
//

#import "ProgressLoadingWindowController.h"

@interface ProgressLoadingWindowController ()

@property (nonatomic, strong) NSProgress *progress;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *statusLabel;

@end

@implementation ProgressLoadingWindowController

- (instancetype)initWithProgress:(NSProgress *)progress {
    if (self = [super initWithWindowNibName:@"ProgressLoadingWindowController"]) {
        self.progress = progress;
        [progress addObserver:self
                   forKeyPath:@"completedUnitCount"
                      options:0
                      context:nil];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    self.progressIndicator.minValue = 0;
    self.progressIndicator.maxValue = self.progress.totalUnitCount;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.progress && [keyPath isEqual:@"completedUnitCount"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self update];
        });
    }
}

- (void)update {
    self.progressIndicator.doubleValue = self.progress.completedUnitCount;
    self.statusLabel.stringValue = [NSString stringWithFormat:@"%lld of %lld", self.progress.completedUnitCount, self.progress.totalUnitCount];
}

@end
