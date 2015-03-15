//
//  DVBAgreementViewController.m
//  dvach-browser
//
//  Created by Andy on 04/11/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBAgreementViewController.h"
#import "DVBConstants.h"

@interface DVBAgreementViewController ()

@property (strong, nonatomic) IBOutlet UIBarButtonItem *notAcceptedBtn;

@end

@implementation DVBAgreementViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    BOOL userAgreementAccepted = [[NSUserDefaults standardUserDefaults] boolForKey:USER_AGREEMENT_ACCEPTED];
    
    if (userAgreementAccepted)
    {
        /**
         *  Do not let user to unaccepted accepted agreement.
         */
        self.notAcceptedBtn.enabled = false;
    }
}
/**
 *  Dismiss modal.
 */
- (IBAction)goBack:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
/**
 *  Set user Defaults - user accepted EULA.
 */
- (IBAction)agreeAction:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_AGREEMENT_ACCEPTED];
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end