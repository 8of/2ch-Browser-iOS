//
//  DVBBoardsModel.h
//  dvach-browser
//
//  Created by Mega on 12/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol DVBBoardsModelDelegate <NSObject>

- (void)updateTable;

@end

@interface DVBBoardsModel : NSObject <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (nonatomic, weak) id<DVBBoardsModelDelegate> boardsModelDelegate;

/**
 *  Should we filter content or show it just as is
 */
@property (nonatomic, readonly) BOOL filterContent;
/**
 *  Array of Boards
 */
@property (nonatomic, readonly) NSArray *boardsArray;
/**
 *  Array of board categroies
 */
@property (nonatomic, strong, readonly) NSArray *boardCategoriesArray;
/**
 *  all in one - cats and their boards
 */
@property (nonatomic, readonly) NSDictionary *boardsDictionaryByCategories;

+ (instancetype)sharedBoardsModel;
/**
 *  Add new board to user list of boards, directly to the Favourite section
 *
 *  @param boardId 's shortCode
 */
- (void)addBoardWithBoardId:(NSString *)boardId;

- (BOOL)saveChanges;

/**
 *  Get board id by providing index of board in array of boards
 *
 *  @param indexPath - indexPath in table to help model give the right board
 *
 *  @return boardId shortcode
 */
- (NSString *)boardIdByIndexPath:(NSIndexPath *)indexPath;

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