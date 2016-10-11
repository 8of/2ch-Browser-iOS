//
//  DVBBoardsViewController.m
//  dvach-browser
//
//  Created by Andy on 16/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBCommon.h"
#import "DVBConstants.h"
#import "DVBBoardsModel.h"
#import "DVBAlertViewGenerator.h"
#import "UrlNinja.h"

#import "DVBBoardsViewController.h"
#import "DVBBoardViewController.h"
#import "DVBThreadViewController.h"

static NSInteger const MAXIMUM_SCROLL_UNTIL_SCROLL_TO_TOP_ON_APPEAR = 190.0f;

@interface DVBBoardsViewController () <DVBAlertViewGeneratorDelegate, DVBBoardsModelDelegate>

/// For storing fetched boards
@property (strong, nonatomic) NSDictionary *boardsDict;
@property (strong, nonatomic) DVBBoardsModel *boardsModel;
@property (strong, nonatomic) DVBAlertViewGenerator *alertViewGenerator;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;

@end

@implementation DVBBoardsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLS(@"TITLE_BOARDS");

    [self darkThemeHandler];
    
    if (!_alertViewGenerator) {
        _alertViewGenerator = [[DVBAlertViewGenerator alloc] init];
        _alertViewGenerator.alertViewGeneratorDelegate = self;
    }
    [self loadBoardList];
    
    // check if EULA accepted or not
    if (![self userAgreementAccepted]) {
        [self performSegueWithIdentifier:SEGUE_TO_EULA sender:self];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setToolbarHidden:YES
                                       animated:NO];

    // Check if table have section 0.
    // Table View always have this 0 section - but it's hidden if user not added favourites.
    if ([self.tableView numberOfRowsInSection:0]) {
        // hide search bar - we can reach it by pull gesture
        NSIndexPath *firstRow = [NSIndexPath indexPathForRow:0 inSection:0];

        // Check if first row is existing - or otherwise app will crash
        // and Check if user scrolled table already or not
        if (firstRow && (self.tableView.contentOffset.y < MAXIMUM_SCROLL_UNTIL_SCROLL_TO_TOP_ON_APPEAR)) {
            [self.tableView scrollToRowAtIndexPath:firstRow
                                  atScrollPosition:UITableViewScrollPositionTop
                                          animated:NO];
        }
    }
}

- (void)darkThemeHandler
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        self.tableView.backgroundColor = [UIColor blackColor];
        [self.tableView setSeparatorColor:CELL_SEPARATOR_COLOR];
        _searchBar.barStyle = UIBarStyleBlackTranslucent;
    }
}

#pragma mark - Board List

- (void)loadBoardList
{
    _boardsModel = [DVBBoardsModel sharedBoardsModel];
    _boardsModel.boardsModelDelegate = self;
    
    self.tableView.dataSource = _boardsModel;
    self.tableView.delegate = _boardsModel;
    _searchBar.delegate = _boardsModel;

    [self updateTable];
}

- (void)addBoardWithCode:(NSString *)code {
    [_boardsModel addBoardWithBoardId:code];
    [self updateTable];
}

- (void)updateTable {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - user Agreement

/**
 *  Check EULA ccepted or not
 *
 *  @return YES if user accepted EULA
 */
- (BOOL)userAgreementAccepted
{
    BOOL userAgreementAccepted = [[NSUserDefaults standardUserDefaults] boolForKey:USER_AGREEMENT_ACCEPTED];
    return userAgreementAccepted;
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([self userAgreementAccepted]) {
        NSIndexPath *selectedCellPath = [self.tableView indexPathForSelectedRow];
        NSString *boardId = [_boardsModel boardIdByIndexPath:selectedCellPath];

        // Check if deal with thread bookmark and not board
        UrlNinja *urlNinja = [[UrlNinja alloc] initWithUrl:[NSURL URLWithString:boardId]];
        if (urlNinja.type == boardThreadLink) {
            urlNinja.threadTitle = [_boardsModel threadTitleByIndexPath:selectedCellPath];
            [self openThreadWithUrlNinja:urlNinja];

            return NO;
        }

        // Cancel opening if app isn't allowed to open the board
        if (![_boardsModel canOpenBoardWithBoardId:boardId]) {
            UIAlertView *alertView = [_alertViewGenerator alertViewForBadBoard];

            [alertView show];

            [self.tableView deselectRowAtIndexPath:selectedCellPath
                                        animated:YES];

            return NO;
        }

        return YES;
    }

    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:SEGUE_TO_BOARD]) {
        
        NSIndexPath *selectedCellPath = [self.tableView indexPathForSelectedRow];
        NSString *boardId = [_boardsModel boardIdByIndexPath:selectedCellPath];
        NSNumber *pages = [_boardsModel boardMaxPageByIndexPath:selectedCellPath];
        
        DVBBoardViewController *boardViewController = segue.destinationViewController;        
        
        // Set board id and pages count for future board/thread requests.
        boardViewController.boardCode = boardId;
        boardViewController.pages = pages.integerValue;
    }
}

#pragma mark - Actions

- (IBAction)showAlertWithBoardCodePrompt:(id)sender {
    // Cancel focus on Search field - or app can crash.
    [self.view endEditing:YES];
    UIAlertView *boardCodeAlertView = [_alertViewGenerator alertViewForBoardCode];
    [boardCodeAlertView show];
}

- (IBAction)openSettingsApp:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

#pragma mark - Thread opener

- (void)openThreadWithUrlNinja:(UrlNinja *)urlNinja
{
    DVBThreadViewController *threadViewControllerToOpen = [self.storyboard instantiateViewControllerWithIdentifier:STORYBOARD_ID_THREAD_VIEW_CONTROLLER];
    threadViewControllerToOpen.boardCode = urlNinja.boardId;
    threadViewControllerToOpen.threadNum = urlNinja.threadId;
    if (urlNinja.threadTitle) {
        threadViewControllerToOpen.threadSubject = urlNinja.threadTitle;
    }

    [self.navigationController pushViewController:threadViewControllerToOpen
                                         animated:YES];
}

@end
