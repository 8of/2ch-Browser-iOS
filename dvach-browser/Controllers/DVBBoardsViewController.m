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

@interface DVBBoardsViewController () <DVBAlertViewGeneratorDelegate, DVBBoardsModelDelegate>

/**
 *  dictionary for storing fetched boards
 */
@property (strong, nonatomic) NSDictionary *boardsDict;
@property (strong, nonatomic) DVBBoardsModel *boardsModel;
@property (strong, nonatomic) DVBAlertViewGenerator *alertViewGenerator;

@end

@implementation DVBBoardsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!_alertViewGenerator) {
        _alertViewGenerator = [[DVBAlertViewGenerator alloc] init];
        _alertViewGenerator.alertViewGeneratorDelegate = self;
    }
    [self loadBoardList];
    /**
     *  check if EULA accepted or not
     */
    if (![self userAgreementAccepted]) {
        [self performSegueWithIdentifier:SEGUE_TO_EULA sender:self];
    }
}

#pragma mark - Board List

- (void)loadBoardList
{
    _boardsModel = [DVBBoardsModel sharedBoardsModel];
    _boardsModel.boardsModelDelegate = self;
    
    self.tableView.dataSource = _boardsModel;
    self.tableView.delegate = _boardsModel;

    [self updateTable];
}

- (void)addBoardWithCode:(NSString *)code {
    [_boardsModel addBoardWithBoardId:code];
    [self updateTable];
}

- (IBAction)showAlertWithBoardCodePrompt:(id)sender {
    UIAlertView *boardCodeAlertView = [_alertViewGenerator alertViewForBoardCode];
    [boardCodeAlertView show];
}

- (void)updateTable {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
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

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier
                                  sender:(id)sender
{
    if ([self userAgreementAccepted] || [identifier isEqualToString:SEGUE_TO_SETTINGS])
    {
        return YES;
    }
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:SEGUE_TO_BOARD]) {
        
        NSIndexPath *selectedCellPath = [self.tableView indexPathForSelectedRow];
        NSString *boardId = [_boardsModel boardIdByIndexPath:selectedCellPath];
        
        // Clear selection after getting all we need from selected cell.
        [self.tableView deselectRowAtIndexPath:selectedCellPath
                                      animated:YES];
        
        // NSUInteger pages = [_boardsModel getBoardPagesWithBoardId:boardId];
        
        DVBBoardViewController *boardViewController = segue.destinationViewController;        
        
        // Set board id and pages count for future board/thread requests.
        boardViewController.boardCode = boardId;
        // boardViewController.pages = pages;
    }
}

@end
