//
//  DVBBoardsModel.h
//  dvach-browser
//
//  Created by Mega on 12/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DVBBoardsModelDelegate <NSObject>
/**
 *  Show alert about EULA.
 */
- (void)showUserAgeementAlert;
/**
 *  Check if EULA accepted or not.
 *
 *  @return YES if accepted
 */
- (BOOL)userAgreementAccepted;

@end

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
@property (nonatomic, weak) id<DVBBoardsModelDelegate> boardsModelDelegate;

/**
 *  Get array of boards to show
 */
- (void)getBoardsWithCompletion:(void (^)(NSDictionary *))completion;

/**
 *  Get shortcode UID for board from array
 */
- (NSString *)getBoardIdWithCategoryName:(NSString *)category
                                andIndex:(NSUInteger)index;
/**
 *  Get board max page
 *
 *  @param board shortcode UID
 *
 *  @return board UI
 */
- (NSUInteger)getBoardPagesWithBoardId:(NSString *)boardId;

@end