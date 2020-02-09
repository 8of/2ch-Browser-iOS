//
//  DVBNetworkImageFixerTests.m
//  dvach-browser
//
//  Created by Andy on 26/02/2017.
//  Copyright © 2017 8of. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MWPhotoBrowser/DVBNetworkImageFixer.h>

@interface DVBNetworkImageFixerTests : XCTestCase

@end

@implementation DVBNetworkImageFixerTests

- (void)testBrokenImageRepair
{
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *path = [bundle pathForResource:@"brokenHeader" ofType:@"jpg"];
  NSURL *imageURL = [[NSURL alloc] initFileURLWithPath:path];
  UIImage *image = [DVBNetworkImageFixer fixedImageFrom:imageURL];
  XCTAssertNotNil(image);
}

@end
