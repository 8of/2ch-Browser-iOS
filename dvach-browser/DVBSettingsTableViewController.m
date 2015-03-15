//
//  DVBSettingsTableViewController.m
//  dvach-browser
//
//  Created by Andy on 09/11/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBSettingsTableViewController.h"
#import "DVBConstants.h"
#import "DVBAlertViewGenerator.h"
#import "DVBNetworking.h"

static NSString *const HELP_CELL_IDENTIFIER = @"helpCell";
static NSString *const PASSCODE_CELL_IDENTIFIER = @"passcodeCell";

@interface DVBSettingsTableViewController () <DVBAlertViewGeneratorDelegate>

@property (nonatomic, strong) DVBNetworking *networking;
@property (nonatomic, strong) DVBAlertViewGenerator *alertViewGenerator;
@property (nonatomic, weak) IBOutlet UITableViewCell *passCodeCell;

/**
 *  Open in Chrome switch
 */
@property (nonatomic, weak) IBOutlet UISwitch *chromeSwitch;

@end

@implementation DVBSettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self viewPreparations];
}
/**
 *  All tunedup on first start
 */
- (void)viewPreparations
{
    _alertViewGenerator = [[DVBAlertViewGenerator alloc] init];
    _alertViewGenerator.alertViewGeneratorDelegate = self;
    
    BOOL isExternalLinksShoulBeOpenedInChrome = [[NSUserDefaults standardUserDefaults] boolForKey:OPEN_EXTERNAL_LINKS_IN_CHROME];
    
    if (isExternalLinksShoulBeOpenedInChrome)
    {
        [_chromeSwitch setOn:YES animated:NO];
    }
    
    [self changeAccessoryForPasscodeCell];
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *clickedCell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString *cellIdentifier = clickedCell.reuseIdentifier;
    if ([cellIdentifier isEqualToString:HELP_CELL_IDENTIFIER])
    {
        [self openHelpPage];
    }
    else if ([cellIdentifier isEqualToString:PASSCODE_CELL_IDENTIFIER])
    {
        /**
         *  Create passcode alertView for user to enter his passcode
         */
        UIAlertView *alertView = [_alertViewGenerator alertViewForPassCodeWithIndexPath:indexPath];
        [alertView show];
        
    }
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}
/**
 *  Open Help web page in an external browser.
 */
- (void)openHelpPage
{
    NSString *urlForFaq;
    /**
     *  Open the link in web browser.
     */
    BOOL isExternalLinksShoulBeOpenedInChrome = [[NSUserDefaults standardUserDefaults] boolForKey:OPEN_EXTERNAL_LINKS_IN_CHROME];
    BOOL canOpenInChrome = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:DVACH_CHROME_FAQ_URL]];
    
    if (isExternalLinksShoulBeOpenedInChrome && canOpenInChrome)
    {
        urlForFaq = DVACH_CHROME_FAQ_URL;
    }
    else
    {
        urlForFaq = DVACH_FAQ_URL;
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlForFaq]];
}

/**
 * Cchange user defaults for Open in Chrome feature
 *
 *  @param state new state for Open in Chrome feature
 */
- (void)changeDefaultOpenAppSettingWithState:(BOOL)state
{
    [[NSUserDefaults standardUserDefaults] setBool:state
                                            forKey:OPEN_EXTERNAL_LINKS_IN_CHROME];
}

#pragma mark - DVBAlertViewGeneratorDelegate

- (void)getUsercodeWithCode:(NSString *)passcode
{
    BOOL isPassCodeBlank = [passcode isEqualToString:@""];
    
    if (isPassCodeBlank)
    {
        /**
         *  Reset default passcode if we reset it through alert
         */
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:USERCODE];
        [self changeAccessoryForPasscodeCell];
    }
    else
    {
        if (!_networking)
        {
            _networking = [[DVBNetworking alloc] init];
        }
        
        [_networking getUserCodeWithPasscode:passcode andCompletion:^(NSString *completion) {
            if (completion)
            {
                [[NSUserDefaults standardUserDefaults] setObject:completion forKey:USERCODE];
                [self changeAccessoryForPasscodeCell];
            }
        }];
    }
}

#pragma mark - Passcode stuff

- (void)changeAccessoryForPasscodeCell
{
    NSString *usercode = [[NSUserDefaults standardUserDefaults] objectForKey:USERCODE];
    BOOL isUsercode = ![usercode isEqualToString:@""];
    
    if (isUsercode)
    {
        _passCodeCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        _passCodeCell.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (IBAction)openInChromeSwtichChangeState:(id)sender
{
    BOOL chromeSwitchState = _chromeSwitch.on;
    [self changeDefaultOpenAppSettingWithState:chromeSwitchState];
}

@end