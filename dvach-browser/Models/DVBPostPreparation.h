//
//  DVBPostPreparation.h
//  dvach-browser
//
//  Created by Andy on 19/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVBPostPreparation : NSObject
/**
 *  Array of posts that have been REPLIED BY current post
 */
@property (nonatomic, strong) NSMutableArray *repliesToArrayForPost;
/**
 *  Init method with board and thread infos
 *
 *  @param boardId  short code of the board
 *  @param threadId number of the op post of the thread
 *
 *  @return Preparation object
 */
- (instancetype)initWithBoardId:(NSString *)boardId andThreadId:(NSString *)threadId;
/**
 *  Add 2ch markup to the comment (based on HTML markup
 *
 *  @param comment plain string with comment
 *
 *  @return attributed string with 2ch markup
 */
- (NSAttributedString *)commentWithMarkdownWithComments:(NSString *)comment;

@end
