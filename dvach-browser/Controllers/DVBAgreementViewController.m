//
//  DVBAgreementViewController.m
//  dvach-browser
//
//  Created by Andy on 04/11/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBCommon.h"
#import "DVBConstants.h"

#import "DVBAgreementViewController.h"

static CGFloat const AGREEMENT_TEXTVIEW_VERTICAL_INSET = 16.0f;
static CGFloat const AGREEMENT_TEXTVIEW_HORISONTAL_INSET = 12.0f;

@interface DVBAgreementViewController ()

@property (nonatomic, weak) IBOutlet UITextView *agreementTextView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *acceptButton;

@end

@implementation DVBAgreementViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLS(@"TITLE_AGREEMENT");
    _agreementTextView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [_agreementTextView setTextContainerInset:UIEdgeInsetsMake(AGREEMENT_TEXTVIEW_VERTICAL_INSET, AGREEMENT_TEXTVIEW_HORISONTAL_INSET, AGREEMENT_TEXTVIEW_VERTICAL_INSET, AGREEMENT_TEXTVIEW_HORISONTAL_INSET)];
    _acceptButton.title = NSLS(@"BUTTON_ACCEPT");
}

/// Set user Defaults - user accepted EULA.
- (IBAction)agreeAction:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_AGREEMENT_ACCEPTED];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
