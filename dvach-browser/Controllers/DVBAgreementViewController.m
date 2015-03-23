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

@end

@implementation DVBAgreementViewController

/**
 *  Set user Defaults - user accepted EULA.
 */
- (IBAction)agreeAction:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_AGREEMENT_ACCEPTED];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
