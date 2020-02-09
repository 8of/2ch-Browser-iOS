//
//  DVBUrlNinjaTest.m
//  dvach-browser
//
//  Created by Andy on 04/06/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "UrlNinja.h"

@interface DVBUrlNinjaTest : XCTestCase

@end

@implementation DVBUrlNinjaTest

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
