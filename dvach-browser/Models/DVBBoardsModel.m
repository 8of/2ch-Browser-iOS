//
//  DVBBoardsModel.m
//  dvach-browser
//
//  Created by Mega on 12/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DVBBoardsModel.h"
#import "DVBNetworking.h"
#import "DVBStatus.h"
#import "DVBValidation.h"
#import "DVBBoardObj.h"
#import "DVBBoardTableViewCell.h"
#import "DVBConstants.h"

@interface DVBBoardsModel ()

@end

@implementation DVBBoardsModel

- (void)getBoardsWithCompletion:(void (^)(NSDictionary *))completion
{
    DVBNetworking *networkHandler = [[DVBNetworking alloc] init];
    DVBStatus *statusModel = [DVBStatus sharedStatus];
    [statusModel setFilterContent:YES];
    [networkHandler getBoardsFromNetworkWithCompletion:^(NSDictionary *boardsDict)
    {
        if (networkHandler.filterContent)
        {
            _filterContent = YES;
            [statusModel setFilterContent:YES];
        }
        else
        {
            _filterContent = NO;
            [statusModel setFilterContent:NO];
        }
        
        /**
         *  Creating empty mutable dictionary for later use.
         */
        NSMutableDictionary *boardsDictionary = [NSMutableDictionary dictionary];
        NSMutableArray *boardsArray = [NSMutableArray array];
        for (id key in boardsDict)
        {
            /**
             *  Deleting the only one specific bad category
             */
            if ([key isEqualToString:@"Взрослым"])
            {
                continue;
            }
            NSArray *boardsInsideCategory = [[NSArray alloc] initWithArray:[boardsDict objectForKey:key]];
            NSMutableArray *boardsGroupArray = [NSMutableArray array];
            for (NSDictionary *singleBoardDictionary in boardsInsideCategory)
            {
                NSString *name = singleBoardDictionary[@"name"];
                NSString *boardId = singleBoardDictionary[@"id"];
                NSInteger pages = [singleBoardDictionary[@"pages"] integerValue];
                
                // I will refactor it later when I'll be rewriting Bad Boards approach.
                DVBValidation *validationObject = [[DVBValidation alloc] init];
                BOOL isCurrentBoardAmongDadOnes = [validationObject checkBadBoardWithBoard:boardId];
                if (isCurrentBoardAmongDadOnes && _filterContent)
                {
                    continue;
                }
                DVBBoardObj *boardObj = [[DVBBoardObj alloc] initWithId:boardId andName:name andPages:pages];
                [boardsGroupArray addObject:boardObj];
                [boardsArray addObject:boardObj];
            }
            boardsDictionary[key] = boardsGroupArray;
        }
        _boardsDictionaryByCategories = boardsDictionary;
        _boardsArray = boardsArray;
        _categoryArray = [boardsDictionary allKeys];

        completion(boardsDictionary);
    }];
};

- (NSString *)getBoardIdWithCategoryName:(NSString *)category
                                andIndex:(NSUInteger)index
{
    if (_boardsDictionaryByCategories)
    {
        DVBBoardObj *boardObject = _boardsDictionaryByCategories[category][index];
        NSString *boardId = boardObject.boardId;
        
        return boardId;
    }
    return @"";
}

- (NSUInteger)getBoardPagesWithBoardId:(NSString *)boardId
{
    NSPredicate *predicateByBoardId = [NSPredicate predicateWithFormat:@"boardId == %@", boardId];
    NSArray *filteredArrayOfBoardsForBoardId = [_boardsArray filteredArrayUsingPredicate:predicateByBoardId];
    
    if ([filteredArrayOfBoardsForBoardId count] > 0)
    {
        DVBBoardObj *boardObj = [filteredArrayOfBoardsForBoardId firstObject];
        NSUInteger pages = boardObj.pages;
        
        return pages;
    }
    return 0;
}
#pragma mark - TableView delegate & DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_categoryArray count];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    NSString *category = _categoryArray[section];
    NSArray *arrForRowCount = _boardsDictionaryByCategories[category];
    
    return [arrForRowCount count];
}

- (DVBBoardTableViewCell *)tableView:(UITableView *)tableView
               cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBBoardTableViewCell *boardCell = [tableView dequeueReusableCellWithIdentifier:BOARD_CELL_IDENTIFIER];
    NSString *category = _categoryArray[indexPath.section];
    NSArray *arrForRowCount = _boardsDictionaryByCategories[category];
    DVBBoardObj *boardObject = arrForRowCount[indexPath.row];
    [boardCell prepareCellWithBoardObject:boardObject];
    
    return boardCell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *categoryTitle = _categoryArray[section];
    
    return categoryTitle;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<DVBBoardsModelDelegate> strongDelegate = _boardsModelDelegate;
    /**
     *  Fire method from delegate
     *
     *  @param showUserAgeementAlert: method shows alert if user agreement wasn't accepted
     */
    if ([strongDelegate respondsToSelector:@selector(userAgreementAccepted)] && [strongDelegate respondsToSelector:@selector(showUserAgeementAlert)]) {
        BOOL isAgreementAccepted = [strongDelegate userAgreementAccepted];
        if (!isAgreementAccepted) {
            [strongDelegate showUserAgeementAlert];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
