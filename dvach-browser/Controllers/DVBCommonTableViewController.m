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

@property (nonatomic, strong) DVBLoadingStatusView *loadingStatusView;

@end

@implementation DVBCommonTableViewController

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
