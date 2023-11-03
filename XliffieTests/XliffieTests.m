//
//  XliffieTests.m
//  XliffieTests
//
//  Created by b123400 on 5/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "Utilities.h"

@interface XliffieTests : XCTestCase

@end

@implementation XliffieTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBatch {
    NSArray *arr = @[@1, @2, @3, @4, @5];
    __block NSInteger i = 0;
    NSArray *result = [Utilities batch:arr limit:2 callback:^id _Nonnull(NSArray * _Nonnull items) {
        if (i == 0) {
            XCTAssert(([items isEqual:@[@1, @2]]), @"first batch");
            i++;
            return @"a";
        } else if (i == 1) {
            XCTAssert(([items isEqual:@[@3, @4]]), @"second batch");
            i++;
            return @"b";
        } else if (i == 2) {
            XCTAssert(([items isEqual:@[@5]]), @"third batch");
            i++;
            return @"c";
        }
        i++;
        return @"d";
    }];
    XCTAssert(([result isEqual:@[@"a", @"b", @"c"]]), @"result");
}

- (void)testDetectCaseDetection {
    StringFormat stringFormat1 = [Utilities detectFormatOfString:@"Hello"];
    XCTAssert(stringFormat1 == StringFormatInitialUpper);
    
    StringFormat stringFormat2 = [Utilities detectFormatOfString:@"hello"];
    XCTAssert(stringFormat2 == StringFormatAllLower);
    
    StringFormat stringFormat3 = [Utilities detectFormatOfString:@"HELLO"];
    XCTAssert(stringFormat3 == StringFormatAllUpper);
}

- (void)testStringFormatApply {
    NSString *str = [Utilities applyFormat:StringFormatAllLower toString:@"heLLo"];
    XCTAssert([str isEqual:@"hello"]);
    
    str = [Utilities applyFormat:StringFormatAllUpper toString:@"heLLo"];
    XCTAssert([str isEqual:@"HELLO"]);
    
    str = [Utilities applyFormat:StringFormatInitialUpper toString:@"heLLo"];
    XCTAssert([str isEqual:@"Hello"]);
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
