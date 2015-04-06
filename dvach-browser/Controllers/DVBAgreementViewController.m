//
//  DVBAgreementViewController.m
//  dvach-browser
//
//  Created by Andy on 04/11/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBAgreementViewController.h"
#import "DVBConstants.h"

static CGFloat const AGREEMENT_TEXTVIEW_VERTICAL_INSET = 8.0f;
static CGFloat const AGREEMENT_TEXTVIEW_HORISONTAL_INSET = 16.0f;

@interface DVBAgreementViewController ()

@property (weak, nonatomic) IBOutlet UITextView *agreementTextView;

@end

@implementation DVBAgreementViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _agreementTextView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [_agreementTextView setTextContainerInset:UIEdgeInsetsMake(AGREEMENT_TEXTVIEW_VERTICAL_INSET, AGREEMENT_TEXTVIEW_HORISONTAL_INSET, AGREEMENT_TEXTVIEW_VERTICAL_INSET, AGREEMENT_TEXTVIEW_HORISONTAL_INSET)];
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
