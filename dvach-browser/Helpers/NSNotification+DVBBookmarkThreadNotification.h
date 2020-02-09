//
//  NSNotification+DVBBookmarkThreadNotification.h
//  dvach-browser
//
//  Created by Andy on 15/11/15.
//  Copyright © 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNotification (DVBBookmarkThreadNotification)

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSString *url;

@end
