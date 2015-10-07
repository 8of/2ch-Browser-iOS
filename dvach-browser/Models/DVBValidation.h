//
//  DVBValidation.h
//  dvach-browser
//
//  Created by Mega on 12/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//
// Validate boards

#import <Foundation/Foundation.h>

@interface DVBValidation : NSObject

/// Check shortcode for presence of different symbols
- (BOOL)checkBoardShortCodeWith:(NSString *)boardCode;

@end
