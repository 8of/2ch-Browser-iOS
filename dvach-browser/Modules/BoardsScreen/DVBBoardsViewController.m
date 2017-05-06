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
#import "DVBAlertGenerator.h"
#import "UrlNinja.h"
#import "DVBDefaultsManager.h"
#import "DVBBoardsViewController.h"
#import "DVBRouter.h"
#import "DVBThread.h"

static NSInteger const MAXIMUM_SCROLL_UNTIL_SCROLL_TO_TOP_ON_APPEAR = 190.0f;

@interface DVBBoardsViewController () <DVBAlertGeneratorDelegate, DVBBoardsModelDelegate>

/// For storing fetched boards
@property (strong, nonatomic) NSDictionary *boardsDict;
@property (nonatomic, strong, nonnull) NSDictionary *defaultsToCompare;
@property (strong, nonatomic) DVBBoardsModel *boardsModel;
@property (strong, nonatomic) DVBAlertGenerator *alertGenerator;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;

@end

@implementation DVBBoardsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _defaultsToCompare = [DVBDefaultsManager initialDefaultsMattersForAppReset];
    self.title = NSLS(@"TITLE_BOARDS");

    [self darkThemeHandler];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(darkThemeHandler)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(goToFirstController)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
      _alertGenerator = [[DVBAlertGenerator alloc] init];
      _alertGenerator.alertGeneratorDelegate = self;
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

- (void)goToFirstController
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)darkThemeHandler
{
    if ([DVBDefaultsManager needToResetWithStoredDefaults:_defaultsToCompare]) {
        [self goToFirstController];
    }

    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        self.tableView.backgroundColor = [UIColor blackColor];
        [self.tableView setSeparatorColor:CELL_SEPARATOR_COLOR_BLACK];
        _searchBar.barStyle = UIBarStyleBlackTranslucent;
    } else {
        self.navigationController.navigationBar.barStyle = UISearchBarStyleDefault;
        self.tableView.backgroundColor = [UIColor whiteColor];
        [self.tableView setSeparatorColor:CELL_SEPARATOR_COLOR];
        _searchBar.barStyle = UIBarStyleDefault;
    }
    [self updateTable];
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

- (void)addBoardWithCode:(NSString *)code
{
    [_boardsModel addBoardWithBoardId:code];
    [self updateTable];
}

#pragma mark - DVBBoardsModelDelegate

- (void)updateTable
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)openWithBoardId:(NSString *)boardId pages:(NSInteger)pages {
  // Cancel opening if app isn't allowed to open the board
  if (![_boardsModel canOpenBoardWithBoardId:boardId]) {
    UIAlertController *alert = [DVBAlertGenerator ageCheckAlert];
    [self presentViewController:alert animated:YES completion:nil];
    return;
  }
  [DVBRouter pushBoardFrom:self boardCode:boardId pages:pages];
}

- (void)openThreadWithUrlNinja:(UrlNinja *)urlNinja
{
  [DVBRouter pushThreadFrom:self
                      board:urlNinja.boardId
                     thread:urlNinja.threadId
                    subject:nil
                    comment:nil];
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
    [self.searchBar endEditing:YES];
    if ([identifier isEqualToString:SEGUE_TO_EULA]) {
        return YES;
    }
    return NO;
}

#pragma mark - Actions

- (IBAction)showAlertWithBoardCodePrompt:(id)sender {
  // Cancel focus on Search field - or app can crash
  [self.view endEditing:YES];
  UIAlertController *boardCodeAlertController = [_alertGenerator boardCodeAlert];
  [self presentViewController:boardCodeAlertController animated:YES completion:nil];
}

- (IBAction)openSettingsApp:(id)sender {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

@end
