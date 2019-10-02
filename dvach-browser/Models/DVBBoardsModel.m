//
//  DVBBoardsModel.m
//  dvach-browser
//
//  Created by Mega on 12/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "DVBCommon.h"
#import "DVBConstants.h"
#import "NSNotification+DVBBookmarkThreadNotification.h"
#import "DVBBoard.h"
#import "DVBNetworking.h"
#import "DVBValidation.h"
#import "DVBBoardsModel.h"
#import "DVBDefaultsManager.h"

#import "DVBBoardTableViewCell.h"

static NSString *const BOARD_STORAGE_FILE_PATH = @"store.data";
static NSString *const DVBBOARD_ENTITY_NAME = @"DVBBoard";
static NSString *const DEFAULT_BOARDS_PLIST_FILENAME = @"DefaultBoards";
static NSString *const BOARD_CATEGORIES_PLIST_FILENAME = @"BoardCategories";

@interface DVBBoardsModel ()

@property (nonatomic, strong) NSMutableArray *boardsPrivate;
@property (nonatomic, strong) NSMutableArray *allBoardsPrivate;

// Core data properties.
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSManagedObjectModel *model;
// Wee need different store (memory) to not store boards gotten from network in DB
@property (nonatomic, strong) NSPersistentStore *memoryStore;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation DVBBoardsModel

#pragma mark - Init and Core Data

+ (instancetype)sharedBoardsModel {
    static DVBBoardsModel *sharedBoardsModel = nil;
    
    if (!sharedBoardsModel) {
        sharedBoardsModel = [[self alloc] initPrivate];
    }
    
    return sharedBoardsModel;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        // Read from datamodel
        _model = [NSManagedObjectModel mergedModelFromBundles:nil];
        
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
        
        // Get path for SQL file.
        NSString *boardsStorageFilePath = [self boardsArchivePath];
        NSURL *boardsStorageURL = [NSURL fileURLWithPath:boardsStorageFilePath];
        NSError *error = nil;
        
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                      configuration:nil
                                                                URL:boardsStorageURL
                                                            options:nil
                                                              error:&error])
        {
            @throw [NSException exceptionWithName:@"OpenFailure" reason:[error localizedDescription] userInfo:nil];
        }
        
        // Create the managed object context
        _context = [[NSManagedObjectContext alloc] init];
        _context.persistentStoreCoordinator = _persistentStoreCoordinator;
        _boardCategoriesArray = [self loadBoardCategoriesFromPlist];
        [self loadAllboards];

        _allBoardsPrivate = _boardsPrivate;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processBookmarkThreadNotification:)
                                                     name:NOTIFICATION_NAME_BOOKMARK_THREAD
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 *  Determining path for loading/saving array of DVBBoards to disk
 *
 *  @return path of file to save to
 */
- (NSString *)boardsArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories firstObject];
    
    return [documentDirectory stringByAppendingPathComponent:BOARD_STORAGE_FILE_PATH];
}

- (BOOL)saveChanges {
    
    NSError *error;
    BOOL successful = [_context save:&error];
    
    if (!successful) {
        NSLog(@"Error saving: %@", [error localizedDescription]);
    }
    
    return successful;
}

/**
 *  Getter method for boardsArray.
 *
 *  @return Array of all boards in model.
 */
- (NSArray *)boardsArray {
    return _boardsPrivate;
}

- (void)loadAllboards
{
    // To prevent from "rebuilding" it
    _memoryStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *wordEntityDescription = [NSEntityDescription entityForName:DVBBOARD_ENTITY_NAME inManagedObjectContext:_context];
    request.entity = wordEntityDescription;
    NSSortDescriptor *sortDescriptorByOrderKey = [NSSortDescriptor sortDescriptorWithKey:@"boardId" ascending:YES];
    request.sortDescriptors = @[sortDescriptorByOrderKey];
    NSError *error;
    NSArray *result = [_context executeFetchRequest:request error:&error];
    
    if (!result) {
        [NSException raise:@"Fetch failed" format:@"Reason: %@", [error localizedDescription]];
    }
    
    NSUInteger boardsCount = [result count];
    
    if (boardsCount) {
        // load from file
        _boardsPrivate = [result mutableCopy];
        [self checkBoardNames];
    } else {
        // create first time
        _boardsPrivate = [@[] mutableCopy];
        [self loadBoardsFromPlist];
    }
}

- (void)addBoardWithBoardId:(NSString *)boardId andBoardName:(NSString *)name andCategoryId:(NSNumber *)categoryId {
    // Constructing DVBBoard with Core Data
    DVBBoard *board = [NSEntityDescription insertNewObjectForEntityForName:DVBBOARD_ENTITY_NAME inManagedObjectContext:_context];
    board.boardId = boardId;
    board.name = name;
    board.categoryId = categoryId;
    
    [_boardsPrivate addObject:board];
}

- (void)addBoardWithBoardId:(NSString *)boardId {
    // Constructing DVBBoard with Core Data
    DVBBoard *board = [NSEntityDescription insertNewObjectForEntityForName:DVBBOARD_ENTITY_NAME inManagedObjectContext:_context];
    board.boardId = boardId;
    board.name = @"";
    
    // 0 - categoryId for favourite category
    NSNumber *favouriteCategoryId = @(0);
    board.categoryId = favouriteCategoryId;
    [_boardsPrivate addObject:board];
    
    [self saveChanges];
    [self loadAllboards];
}

- (void)addThreadWithUrl:(NSString *)url andThreadTitle:(NSString *)title {
    // Constructing DVBBoard with Core Data
    DVBBoard *board = [NSEntityDescription insertNewObjectForEntityForName:DVBBOARD_ENTITY_NAME inManagedObjectContext:_context];
    board.boardId = url;
    board.name = title;

    // 0 - categoryId for favourite category
    NSNumber *favouriteCategoryId = @(0);
    board.categoryId = favouriteCategoryId;
    [_boardsPrivate addObject:board];

    // Sort new array
    NSSortDescriptor *sortDescriptorByOrderKey = [NSSortDescriptor sortDescriptorWithKey:@"boardId" ascending:YES];
    _boardsPrivate = [[[_boardsPrivate copy] sortedArrayUsingDescriptors:@[sortDescriptorByOrderKey]] mutableCopy];

    [self saveChanges];
    [_boardsModelDelegate updateTable];
}

- (void)loadBoardsFromPlist {
    // Get default boards from plist
    NSArray *defaultBoardsArray =[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:DEFAULT_BOARDS_PLIST_FILENAME ofType:@"plist"]];
    
    for (id board in defaultBoardsArray) {
        NSString *boardId = board[@"boardId"];
        NSString *boardName = board[@"name"];
        NSNumber *categoryId = board[@"categoryId"];
        
        [self addBoardWithBoardId:boardId
                     andBoardName:boardName
                    andCategoryId:categoryId];
    }

    [self saveChanges];
    [self loadAllboards];
}

- (NSArray *)loadBoardCategoriesFromPlist {
    // get category names from plist
    return [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:BOARD_CATEGORIES_PLIST_FILENAME ofType:@"plist"]];
}

- (void)getBoardsWithCompletion:(void (^)(NSArray *))completion {
    DVBNetworking *networkHandler = [[DVBNetworking alloc] init];
    weakify(self);
    [networkHandler getBoardsFromNetworkWithCompletion:^(NSDictionary *boardsDict) {
        strongify(self);
        NSMutableArray *boardsFromNetworkMutableArray = [NSMutableArray array];
        for (id key in boardsDict) {
            NSArray *boardsInsideCategory = [[NSArray alloc] initWithArray:[boardsDict objectForKey:key]];
            for (NSDictionary *singleBoardDictionary in boardsInsideCategory) {
                NSString *boardId = singleBoardDictionary[@"id"];
                NSString *name = singleBoardDictionary[@"name"];
                NSNumber *pages = singleBoardDictionary[@"pages"];
                
                DVBBoard *board = [NSEntityDescription insertNewObjectForEntityForName:DVBBOARD_ENTITY_NAME inManagedObjectContext:self.context];
                [self.context assignObject:board toPersistentStore:self.memoryStore];
                board.boardId = boardId;
                board.name = name;
                board.pages = pages;
                
                [boardsFromNetworkMutableArray addObject:board];
                
                // Need to delete this temp created object or it will appear in table after realoading
                [self.context deleteObject:board];
            }
        }
        NSArray *boardsFromNetworkArray = boardsFromNetworkMutableArray;
        completion(boardsFromNetworkArray);
    }];
};

- (void)checkBoardNames {
    BOOL isNeedToLoadBoardsFromNetwork = NO;

    for (DVBBoard *board in self.boardsArray) {
        NSString *name = board.name;
        BOOL isNameEmpty = [name isEqualToString:@""];
        if (isNameEmpty) {
            isNeedToLoadBoardsFromNetwork = YES;
            break;
        }
    }

    if (isNeedToLoadBoardsFromNetwork) {
        NSMutableArray *arrayForInterating = [self.boardsArray mutableCopy];
        weakify(self);
        [self getBoardsWithCompletion:^(NSArray *completion) {
            strongify(self);
            NSUInteger indexOfCurrentBoard = 0;
            for (DVBBoard *board in arrayForInterating) {
                NSString *name = board.name;
                NSString *boardId = board.boardId;
                BOOL isNameEmpty = [name isEqualToString:@""];
                if (isNameEmpty) {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(boardId == %@)", boardId];
                    NSArray *matchedBoardsFromNetwork = [completion filteredArrayUsingPredicate:predicate];
                    NSUInteger matchedBoardsCount = [matchedBoardsFromNetwork count];
                    if (matchedBoardsCount > 0) {
                        DVBBoard *boardFromNetwork = matchedBoardsFromNetwork[0];
                        NSString *nameOfTheMatchedBoard = boardFromNetwork.name;
                        NSNumber *pages = boardFromNetwork.pages;
                        board.name = nameOfTheMatchedBoard;
                        board.pages = pages;
                        [self.boardsPrivate setObject:board atIndexedSubscript:indexOfCurrentBoard];
                    }
                }
                indexOfCurrentBoard++;
            }
            [self saveChanges];
            [self.boardsModelDelegate updateTable];
        }];
    }
}

#pragma mark - TableView delegate & DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_boardCategoriesArray count];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    if ([DVBDefaultsManager isDarkMode]) {
        header.textLabel.textColor = [UIColor whiteColor];
        header.contentView.backgroundColor = CELL_SEPARATOR_COLOR_BLACK;
    } else {
        header.textLabel.textColor = [UIColor blackColor];
        header.contentView.backgroundColor = [UIColor colorWithRed:(247.0/255.0) green:(247.0/255.0) blue:(247.0/255.0) alpha:1.0];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *categoryTitle = NSLS(_boardCategoriesArray[section]);

    // Do not show category at all if category does not contain boards
    BOOL isCategoryEmpty = ([self countOfBoardsInCategoryWithIndex:section] == 0);

    if (isCategoryEmpty) {
        return nil;
    }

    return categoryTitle;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self countOfBoardsInCategoryWithIndex:section];
}

- (DVBBoardTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBBoardTableViewCell *boardCell = [tableView dequeueReusableCellWithIdentifier:BOARD_CELL_IDENTIFIER];
    NSUInteger categoryIndex = indexPath.section;
    NSArray *boardsArrayInCategory = [self arrayForCategoryWithIndex:categoryIndex];
    DVBBoard *board = boardsArrayInCategory[indexPath.row];

    NSString *boardId = board.boardId;

    // Cunstruct different title for threads in list (if any)
    if (indexPath.section == 0) {
        UrlNinja *urlNinja = [[UrlNinja alloc] initWithUrl:[NSURL URLWithString:boardId]];
        if (urlNinja.type == boardThreadLink) {
            boardId = [NSString stringWithFormat:@"/%@/%@",urlNinja.boardId, urlNinja.threadId];
        }
    }

    [boardCell prepareCellWithId:boardId
                    andBoardName:board.name];
    
    return boardCell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Permit editing only items of the Favourite section
    NSUInteger section = indexPath.section;
    if (section == 0) {
        return YES;
    }
    return NO;
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *change = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                                                      title:NSLS(@"BUTTON_CHANGE")
                                                                    handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                    {
                                        [self changeActionForTableView:tableView indexPath:indexPath];
                                    }];
    change.backgroundColor = [UIColor orangeColor];

    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                                      title:NSLS(@"BUTTON_DELETE")
                                                                    handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                     {
                                         [self deleteActionForTableView:tableView indexPath:indexPath];
                                     }];
    return @[delete, change];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Method should be here even if it's empty
}

- (void)changeActionForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    [tableView endEditing:YES];
    NSMutableArray *arrayForInterating = [_boardsPrivate mutableCopy];
    NSString *boardIdToDeleteFromFavourites = [self boardIdByIndexPath:indexPath];
    NSUInteger indexOfCurrentBoard = 0;

    for (DVBBoard *board in arrayForInterating) {
        NSString *boardId = board.boardId;
        NSNumber *boardCategoryId = board.categoryId;
        NSNumber *favouritesCategoryid = [NSNumber numberWithInt:0];
        BOOL isBoardIdEquals = [boardId isEqualToString:boardIdToDeleteFromFavourites];
        BOOL isInFavourites = ([boardCategoryId intValue] == [favouritesCategoryid intValue]);
        if (isBoardIdEquals && isInFavourites) {
            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLS(@"ALERT_CHANGE_FAVOURITE_TITLE") message:nil preferredStyle:UIAlertControllerStyleAlert];

            [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.text = board.name;
                [textField becomeFirstResponder];
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLS(@"BUTTON_CANCEL")
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * _Nonnull action) {

            }];
            [alertVC addAction:cancelAction];

            UIAlertAction *changeAction = [UIAlertAction actionWithTitle:NSLS(@"BUTTON_SAVE")
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * _Nonnull action) {
                UITextField *field = alertVC.textFields.firstObject;
                NSString *text = field.text;
                if (!text || [text isEqualToString:@""]) {
                    return;
                }
                DVBBoard *board = self.boardsPrivate[indexOfCurrentBoard];
                board.name = text;
                [self saveChanges];
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }];
            [alertVC addAction:changeAction];

            if (_boardsModelDelegate) {
                UIViewController *vc = (UIViewController *)_boardsModelDelegate;
                [vc presentViewController:alertVC animated:YES completion:nil];
            }

            break;
        }
        indexOfCurrentBoard++;
    }
}

- (void)deleteActionForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *arrayForInterating = [_boardsPrivate mutableCopy];
    NSString *boardIdToDeleteFromFavourites = [self boardIdByIndexPath:indexPath];
    NSUInteger indexOfCurrentBoard = 0;

    for (DVBBoard *board in arrayForInterating) {
        NSString *boardId = board.boardId;
        NSNumber *boardCategoryId = board.categoryId;
        NSNumber *favouritesCategoryid = [NSNumber numberWithInt:0];
        BOOL isBoardIdEquals = [boardId isEqualToString:boardIdToDeleteFromFavourites];
        BOOL isInFavourites = ([boardCategoryId intValue] == [favouritesCategoryid intValue]);
        if (isBoardIdEquals && isInFavourites) {
            [_boardsPrivate removeObjectAtIndex:indexOfCurrentBoard];
            [_context deleteObject:board];
            break;
        }
        indexOfCurrentBoard++;
    }
    [self saveChanges];

    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *boardId = [self boardIdByIndexPath:indexPath];
    NSNumber *pages = [self boardMaxPageByIndexPath:indexPath];

    // Check if deal with thread bookmark and not board
    UrlNinja *urlNinja = [[UrlNinja alloc] initWithUrl:[NSURL URLWithString:boardId]];
    if (urlNinja.type == boardThreadLink) {
        urlNinja.threadTitle = [self threadTitleByIndexPath:indexPath];
        [_boardsModelDelegate openThreadWithUrlNinja:urlNinja];
    } else { // board
        [_boardsModelDelegate openWithBoardId:boardId
                                        pages:pages.integerValue];
    }
}


- (NSString *)boardIdByIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *boardsInThecategoryArray = [self arrayForCategoryWithIndex:indexPath.section];
    DVBBoard *board = boardsInThecategoryArray[indexPath.row];
    NSString *boardId = board.boardId;
    
    return boardId;
}

- (NSString *)threadTitleByIndexPath:(NSIndexPath *)indexPath
{
    NSArray *boardsInThecategoryArray = [self arrayForCategoryWithIndex:indexPath.section];
    DVBBoard *board = boardsInThecategoryArray[indexPath.row];
    NSString *threadTitle = board.name;

    return threadTitle;
}

- (NSNumber *)boardMaxPageByIndexPath:(NSIndexPath *)indexPath
{
    NSArray *boardsInThecategoryArray = [self arrayForCategoryWithIndex:indexPath.section];
    DVBBoard *board = boardsInThecategoryArray[indexPath.row];
    return board.pages;
}

- (BOOL)canOpenBoardWithBoardId:(NSString *)boardId
{
    BOOL ageCheckStatusOk = [[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_AGE_CHECK_STATUS];
    if (ageCheckStatusOk) {
        return YES;
    }

    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"BadBoards"
                                                          ofType:@"plist"];

    NSArray *badBoards = [NSArray arrayWithContentsOfFile:plistPath];

    if (![badBoards containsObject:boardId]) {
        return YES;
    }

    return NO;
}

#pragma mark - Table helpers

- (NSArray *)arrayForCategoryWithIndex:(NSUInteger)index {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(categoryId == %ld)", index];
    NSArray *matchedBoardsResult = [self.boardsArray filteredArrayUsingPredicate:predicate];
    
    return matchedBoardsResult;
}

- (NSUInteger)countOfBoardsInCategoryWithIndex:(NSUInteger)index
{
    NSArray *matchedBoardsResult = [self arrayForCategoryWithIndex:index];
    return [matchedBoardsResult count];
}

- (void)updateTableWithSearchText:(NSString *)searchText
{
    if (!searchText) {
        _boardsPrivate = _allBoardsPrivate;
    } else {
        _boardsPrivate = [[self getArrayOfBoardsWithSearchText:searchText] mutableCopy];
    }
    [_boardsModelDelegate updateTable];
}

- (NSArray *)getArrayOfBoardsWithSearchText:(NSString *)searchText
{
    NSArray *fullBoarsArray = [_allBoardsPrivate copy];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(name contains[cd] %@) || (boardId contains[cd] %@)", searchText, searchText];
    NSArray *filteredArray = [fullBoarsArray filteredArrayUsingPredicate:predicate];
    return filteredArray;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar endEditing:YES];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES
                           animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar setText:@""];
    [searchBar setShowsCancelButton:NO
                           animated:YES];
    [self updateTableWithSearchText:nil];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSUInteger countOfLetters = searchText.length;
    NSUInteger minimalCountOfCharactersToStartSearch = 1;

    if (countOfLetters >= minimalCountOfCharactersToStartSearch) {
        [self updateTableWithSearchText:searchText];
    } else {
        [self updateTableWithSearchText:nil];
    }
}

#pragma mark - Notifications

- (void)processBookmarkThreadNotification:(NSNotification *)notification
{
    [self addThreadWithUrl:notification.url
            andThreadTitle:notification.title];
}

@end
