//
//  DVBCommonTableViewController.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 13/06/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBCommon.h"
#import "DVBConstants.h"
#import "DVBAlertViewGenerator.h"

#import "DVBCommonTableViewController.h"

#import "DVBLoadingStatusView.h"

@interface DVBCommonTableViewController ()

@property (nonatomic, assign) BOOL eulaAgreed;

@property (nonatomic, strong) DVBLoadingStatusView *loadingStatusView;

@end

@implementation DVBCommonTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _eulaAgreed = [[NSUserDefaults standardUserDefaults] boolForKey:USER_AGREEMENT_ACCEPTED];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSUserDefaultsDidChangeNotification
                                                  object:nil];
}

- (void)defaultsChanged
{
    UIViewController *vc = [[self.navigationController viewControllers] firstObject];

    BOOL isEulaAcceptedNow = [[NSUserDefaults standardUserDefaults] boolForKey:USER_AGREEMENT_ACCEPTED];

    BOOL isUserAgreementUserDefaultTheSame = _eulaAgreed == isEulaAcceptedNow;

    _eulaAgreed = isEulaAcceptedNow;

    // Check if current VC is last one in stack - so we will not present the same message over and over
    // And there is no need to present message when user just accepted EULA
    if ([vc isEqual:self] && isUserAgreementUserDefaultTheSame) {
        DVBAlertViewGenerator *alertGenerator = [[DVBAlertViewGenerator alloc] init];
        NSString *restartAppAlertTitle = NSLS(@"ALERT_SETTINGS_CHANGED_TITLE");
        NSString *restartAppAlertDescription = NSLS(@"ALERT_SETTINGS_CHANGED_MESSAGE");
        UIAlertView *alertView = [alertGenerator alertViewWithTitle:restartAppAlertTitle
                                                        description:restartAppAlertDescription
                                                            buttons:@[NSLS(@"BUTTON_OK")]];
        [alertView show];
    }
}

#pragma mark - Messages about state

- (void)showMessageAboutDataLoading
{
    NSString *loadingTitle = NSLS(@"STATUS_LOADING");
    [self showUserMessageWithTitle:loadingTitle];
}

- (void)showMessageAboutError
{
    NSString *errorTitle = NSLS(@"STATUS_LOADING_ERROR");
    [self showUserMessageWithTitle:errorTitle];
}

- (void)showUserMessageWithTitle:(NSString *)title
{
    if (!_loadingStatusView.loadingStatusViewStyle == DVBLoadingStatusViewStyleError) {
        DVBLoadingStatusViewColor loadingStatusViewColor = DVBLoadingStatusViewColorLight;
        DVBLoadingStatusViewStyle loadingStatusViewStyle = DVBLoadingStatusViewStyleLoading;

        if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
            loadingStatusViewColor = DVBLoadingStatusViewColorDark;
        }

        if ([title isEqualToString:NSLS(@"STATUS_LOADING_ERROR")]) {
            loadingStatusViewStyle = DVBLoadingStatusViewStyleError;
        }

        _loadingStatusView = [[DVBLoadingStatusView alloc] initWithMessage:title
                                                                  andStyle:loadingStatusViewStyle
                                                                  andColor:loadingStatusViewColor];

        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

        double delayInSeconds = 1.0;

        // Error message sgould be presented instantly
        if (loadingStatusViewStyle == DVBLoadingStatusViewStyleError) {
            delayInSeconds = 0.;
        }

        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

            // Check if table is OK
            if (self.tableView) {

                // If no sections showed or if error type of view
                if (self.tableView.numberOfSections == 0 ||
                    loadingStatusViewStyle == DVBLoadingStatusViewStyleError)
                {
                    // More specific double-check
                    if ((loadingStatusViewStyle == DVBLoadingStatusViewStyleLoading &&
                        ![self.tableView.backgroundColor isKindOfClass:self.class]) ||
                        loadingStatusViewStyle == DVBLoadingStatusViewStyleError)
                    {
                        self.tableView.backgroundView = _loadingStatusView;
                    }
                }
            }
        });
    }
}

@end
