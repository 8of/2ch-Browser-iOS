//
//  DVBBoardsModel.h
//  dvach-browser
//
//  Created by Mega on 12/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVBBoardsModel : NSObject <UITableViewDataSource, UITableViewDelegate>

/**
 *  Should we filter content or show it just as is
 */
@property (nonatomic, readonly) BOOL filterContent;
/**
 *  Array of board categroies
 */
@property (nonatomic, readonly) NSArray *categoryArray;
/**
 *  Array of Boards
 */
@property (nonatomic, readonly) NSArray *boardsArray;
/**
 *  all in one - cats and their boards
 */
@property (nonatomic, readonly) NSDictionary *boardsDictionaryByCategories;

+ (instancetype)sharedBoardsModel;

- (void)addBoardWithBoardId:(NSString *)boardId andBoardName:(NSString *)name;
/**
 *  Add new board to user list of boards
 *
 *  @param boardId 's shortCode
 */
- (void)addBoardWithBoardId:(NSString *)boardId;

- (BOOL)saveChanges;

/**
 *  Get board id by providing index of board in array of boards
 *
 *  @param index - index of specific board in arrya of boards
 *
 *  @return boardId shortcode
 */
- (NSString *)boardIdByIndex:(NSUInteger)index;

/**
 *  Get array of boards to show
 */
// - (void)getBoardsWithCompletion:(void (^)(NSDictionary *))completion;

/**
 *  Get shortcode UID for board from array
 */
// - (NSString *)getBoardIdWithCategoryName:(NSString *)category
//                                 andIndex:(NSUInteger)index;
/**
 *  Get board max page
 *
 *  @param board shortcode UID
 *
 *  @return board UI
 */
// - (NSUInteger)getBoardPagesWithBoardId:(NSString *)boardId;

@end