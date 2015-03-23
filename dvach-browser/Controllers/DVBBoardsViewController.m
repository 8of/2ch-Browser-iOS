//
//  DVBBoardsViewController.m
//  dvach-browser
//
//  Created by Andy on 16/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//
#import "DVBBoardsViewController.h"
#import "DVBBoardViewController.h"

#import "DVBConstants.h"
#import "DVBBoardsModel.h"
#import "DVBAlertViewGenerator.h"

@interface DVBBoardsViewController () <DVBAlertViewGeneratorDelegate>

/**
 *  dictionary for storing fetched boards
 */
@property (strong, nonatomic) NSDictionary *boardsDict;
/**
 *  pass this param when open boardVC with segue
 */
@property (strong, nonatomic) NSString *boardToOpen;
@property (strong, nonatomic) DVBBoardsModel *boardsModel;
@property (strong, nonatomic) DVBAlertViewGenerator *alertViewGenerator;

@end

@implementation DVBBoardsViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!_alertViewGenerator)
    {
        _alertViewGenerator = [[DVBAlertViewGenerator alloc] init];
        _alertViewGenerator.alertViewGeneratorDelegate = self;
    }
    /**
     *  check if EULA accepted or not
     */
    if (![self userAgreementAccepted])
    {
        [self performSegueWithIdentifier:SEGUE_TO_EULA sender:self];
    }
    _boardToOpen = @"";
    [self loadBoardList];
}

- (void)loadBoardList
{
    _boardsModel = [[DVBBoardsModel alloc] init];
    self.tableView.dataSource = _boardsModel;
    self.tableView.delegate = _boardsModel;
    // self.tableView.rowHeight = 44.0f;
    [_boardsModel getBoardsWithCompletion:^(NSDictionary *boardsDict)
    {
        if ([boardsDict count] > 0)
        {
            [self.tableView reloadData];
            NSLog(@"Boards LOADED");
        }
    }];
}

#pragma  mark - Open Board Delegate

- (void)openBoardWithCode:(NSString *)code
{
    _boardToOpen = code;
    [self performSegueWithIdentifier:SEGUE_TO_BOARD sender:self];
}

#pragma mark - user Agreement

/**
 *  apple force me to show users an EULA before they can start using my app - so alert just showing users that agreement need to be accepted on settings screen
 *
 *  @return YES if user accepted EULA
 */
- (BOOL)userAgreementAccepted
{
    BOOL userAgreementAccepted = [[NSUserDefaults standardUserDefaults] boolForKey:USER_AGREEMENT_ACCEPTED];
    return userAgreementAccepted;
}

#pragma mark - Navigation

- (IBAction)openBoard:(id)sender
{
    [self checkUserAgreementAndOpenBoard];
}

- (void)checkUserAgreementAndOpenBoard
{
    if ([self userAgreementAccepted])
    {
        /**
         open board with alert view and shortcode
         
         :returns: alertView with shortcode prompt
         */
        UIAlertView *alertView = [_alertViewGenerator alertViewForBoardCode];
        [alertView show];
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier
                                  sender:(id)sender
{
    if ([self userAgreementAccepted] || [identifier isEqualToString:SEGUE_TO_SETTINGS])
    {
        return YES;
    }
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([[segue identifier] isEqualToString:SEGUE_TO_BOARD])
    {
        
        NSString *boardId;
        
        if ([_boardToOpen isEqualToString:@""])
        {
            NSIndexPath *selectedCellPath = [self.tableView indexPathForSelectedRow];
            NSString *category = _boardsModel.categoryArray[selectedCellPath.section];
            boardId = [_boardsModel getBoardIdWithCategoryName:category
                                                      andIndex:selectedCellPath.row];
            /**
             *  Clear selection after getting all we need from selected cell.
             */
            [self.tableView deselectRowAtIndexPath:selectedCellPath
                                          animated:YES];
        }
        else
        {
            boardId = _boardToOpen;
            /**
             *  Reset variable for future reuse.
             */
            _boardToOpen = @"";
        }
        
        NSUInteger pages = [_boardsModel getBoardPagesWithBoardId:boardId];
        
        DVBBoardViewController *boardViewController = segue.destinationViewController;        
        
        /**
         *  Set board id and pages count for future board/thread requests.
         */
        boardViewController.boardCode = boardId;
        boardViewController.pages = pages;
    }
}

@end
