//
//  DVBAsyncThreadViewController.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 18/12/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVBAsyncThreadViewController : ASViewController

- (instancetype)initWithBoardCode:(NSString *)boardCode andThreadNumber:(NSString *)threadNumber andThreadSubject:(NSString *)subject;

@end

NS_ASSUME_NONNULL_END
