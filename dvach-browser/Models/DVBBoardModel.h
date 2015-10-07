//
//  DVBBoardModel.h
//  dvach-browser
//
//  Created by Andy on 10/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVBBoardModel : NSObject

/// Array contains all threads' OP posts for one page.
@property (nonatomic, strong, readonly) NSArray *threadsArray;

- (instancetype)initWithBoardCode:(NSString *)boardCode andMaxPage:(NSUInteger)maxPage;
/// Load next page for the current board
- (void)loadNextPageWithCompletion:(void (^)(NSArray *))completion;
/// Entirely reload threads list in the board
- (void)reloadBoardWithCompletion:(void (^)(NSArray *))completion;

@end
