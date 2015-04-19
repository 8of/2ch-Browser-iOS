//
//  DVBComment.h
//  dvach-browser
//
//  Created by Mega on 28/01/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

/**
 *  Comment, shared across all app
 */

#import <Foundation/Foundation.h>

@interface DVBComment : NSObject
{
    NSString *comment;
}

@property (nonatomic, retain) NSString *comment;

+ (id)sharedComment;
/**
 *  Add post number to answer text as an address
 *
 *  @param postNum post number we want to answer in our comment
 */
- (void)topUpCommentWithPostNum:(NSString *)postNum;
/**
 *  Add post number to answer text as an address and original post text as a quote
 *
 *  @param postNum          post number we want to answer in our comment
 *  @param originalPostText full post text to use as a quote
 *  @param quoteString      selected part of the post text to use as a quote
 */
- (void)topUpCommentWithPostNum:(NSString *)postNum andOriginalPostText:(NSAttributedString *)originalPostText andQuoteString:(NSString *)quoteString;

@end
