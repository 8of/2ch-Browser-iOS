//
//  DVBBadPost.h
//  dvach-browser
//
//  Created by Andy on 08/11/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

/**
 *  Object for storing information about bad posts inside phone.
 *  Bad posts are posts marked by user - they're not showing to user anymore (on this specific phone).
 */

#import <Foundation/Foundation.h>

@interface DVBBadPost : NSObject <NSCoding>
/**
 *  Number of the bad post.
 */
@property (strong, nonatomic) NSString *num;
/**
 *  Mark is it open post or not (for hiding entire threads).
 */
@property (assign, nonatomic) BOOL threadOrNot;

- (instancetype)initWithNum:(NSString *)postNum
                threadOrNot:(BOOL)trOrNt;


@end