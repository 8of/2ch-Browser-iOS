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

/// Array of Boards
@property (nonatomic, readonly) NSArray *boardsArray;
/// Array of board categroies
@property (nonatomic, strong, readonly) NSArray *boardCategoriesArray;
/// All in one - cats and their boards
@property (nonatomic, readonly) NSDictionary *boardsDictionaryByCategories;

+ (instancetype)sharedBoardsModel;
/**
 *  Add new board to user list of boards, directly to the Favourite section
 *
 *  @param boardId 's shortCode
 */
- (void)addBoardWithBoardId:(NSString *)boardId;

/// Adding favourite THREADS
- (void)addThreadWithUrl:(NSString *)url andThreadTitle:(NSString *)title;

- (BOOL)saveChanges;

/**
 *  Get board id by providing index of board in array of boards
 *
 *  @param indexPath - indexPath in table to help model give the right board
 *
 *  @return boardId shortcode
 */
- (NSString *)boardIdByIndexPath:(NSIndexPath *)indexPath;

/// Get thread title from model
- (NSString *)threadTitleByIndexPath:(NSIndexPath *)indexPath;

/// Check if board ID is not forbidden for opening
- (BOOL)canOpenBoardWithBoardId:(NSString *)boardId;

/// Check review status if needed
+ (void)manageReviewStatus;

@end