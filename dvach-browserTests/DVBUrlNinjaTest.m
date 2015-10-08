//
//  DVBUrlNinjaTest.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 04/06/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "UrlNinja.h"

@interface DVBUrlNinjaTest : XCTestCase

@end

@implementation DVBUrlNinjaTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testUrlTypeShouldBeBoardLink
{
    NSURL *urlToTest = [[NSURL alloc] initWithString:@"https://2ch.hk/mobi/"];
    UrlNinja *url = [[UrlNinja alloc] initWithUrl:urlToTest];
    XCTAssertEqual(url.type, boardLink, @"Should be external link");
}

- (void)testUrlTypeShouldBeBoardThreadLink
{
    NSURL *urlToTest = [[NSURL alloc] initWithString:@"https://2ch.hk/mobi/res/531218.html"];
    UrlNinja *url = [[UrlNinja alloc] initWithUrl:urlToTest];
    XCTAssertEqual(url.type, boardThreadLink, @"Should be external link");
}

- (void)testUrlTypeShouldBeBoardThreadPostLink
{
    NSURL *urlToTest = [[NSURL alloc] initWithString:@"https://2ch.hk/mobi/res/472567.html#532581"];
    UrlNinja *url = [[UrlNinja alloc] initWithUrl:urlToTest];
    XCTAssertEqual(url.type, boardThreadPostLink, @"Should be external link");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
