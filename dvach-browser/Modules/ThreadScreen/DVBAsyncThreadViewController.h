//
//  DVBAsyncThreadViewController.h
//  dvach-browser
//
//  Created by Andy on 18/12/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@class DVBPostViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface DVBAsyncThreadViewController : ASViewController

- (instancetype)initWithBoardCode:(NSString *)boardCode andThreadNumber:(NSString *)threadNumber andThreadSubject:(NSString *)subject;

- (instancetype)initWithPostNum:(NSString *)postNum answers:(NSArray <DVBPostViewModel *> *)answers allPosts:(NSArray <DVBPostViewModel *> *)allPosts;

@end

NS_ASSUME_NONNULL_END
