//
//  DVBThread.h
//  dvach-browser
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

/**
 *  Object for storing information about specific thread
 *
 *  @return Object with full info about board
 */

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVBThread : MTLModel <MTLJSONSerializing>

/// UID of the open post of the thread.
@property (nonatomic, strong) NSString *num;
/// Subject of the thread
@property (nonatomic, strong) NSString *subject;
/// Text of open post message.
@property (nonatomic, strong) NSString *comment;
/// Count of posts inside given thread.
@property (nonatomic, strong) NSNumber *postsCount;
/// Path for open post's thumnail image
@property (nonatomic, strong) NSString *thumbnail;

@property (nonatomic, strong) NSString *timeSinceFirstPost;

+ (BOOL)isTitle:(NSString *)title madeFromComment:(NSString *)comment;
+ (NSString *)threadControllerTitleFromTitle:(NSString *)title andNum:(nullable NSString *)num andComment:(nullable NSString *)comment;
+ (NSString *)threadTitleFromTitle:(NSString *)title andNum:(NSString *)num andComment:(NSString *)comment;

@end

NS_ASSUME_NONNULL_END
