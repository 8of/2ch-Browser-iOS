//
//  DVBCreatePostViewControllerDelegate.h
//  dvach-browser
//
//  Created by Andy on 16/11/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DVBCreatePostViewControllerDelegate <NSObject>

@optional
/// Open thread after creating
- (void)openThredWithCreatedThread:(NSString *)threadNum;
/// Update thread after posting
- (void)updateThreadAfterPosting;

@end
