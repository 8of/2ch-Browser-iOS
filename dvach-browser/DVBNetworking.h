//
//  DVBNetworking.h
//  dvach-browser
//
//  Created by Andy on 10/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVBNetworking : NSObject

@property (nonatomic, readonly) BOOL filterContent;

- (void)getServiceStatusLater:(void (^)(NSUInteger))completion;
- (void)getBoardsFromNetworkWithCompletion:(void (^)(NSDictionary *))completion;

/**
 *  Get posts for single page of single board
 */
- (void)getThreadsWithBoard:(NSString *)board
                    andPage:(NSUInteger)page
              andCompletion:(void (^)(NSDictionary *))completion;

/**
 *  Get usercode cookie in exchange to user's passcode
 */
- (void)getUserCodeWithPasscode:(NSString *)passcode
                  andCompletion:(void (^)(NSString *))completion;

@end