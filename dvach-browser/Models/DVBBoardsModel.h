//
//  DVBBoardsModel.h
//  dvach-browser
//
//  Created by Mega on 12/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "UrlNinja.h"

@protocol DVBBoardsModelDelegate <NSObject>

- (void)updateTable;
- (void)openWithBoardId:(NSString *)boardId pages:(NSInteger)pages;
- (void)openThreadWithUrlNinja:(UrlNinja *)urlNinja;

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

- (instancetype)init NS_UNAVAILABLE;

/// Add new board to user list of boards, directly to the Favourite section
- (void)addBoardWithBoardId:(NSString *)boardId;

/// Adding favourite THREADS
- (void)addThreadWithUrl:(NSString *)url andThreadTitle:(NSString *)title;

- (BOOL)saveChanges;

/// Get board id by providing index of board in array of boards
- (NSString *)boardIdByIndexPath:(NSIndexPath *)indexPath;

/// Get thread title from model
- (NSString *)threadTitleByIndexPath:(NSIndexPath *)indexPath;

/// Max pages count for board
- (NSNumber *)boardMaxPageByIndexPath:(NSIndexPath *)indexPath;

/// Check if board ID is not forbidden for opening
- (BOOL)canOpenBoardWithBoardId:(NSString *)boardId;

@end
