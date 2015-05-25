//
//  DVBActionsForPostTableViewCell.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 03/05/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBConstants.h"

#import "DVBActionsForPostTableViewCell.h"

@interface DVBActionsForPostTableViewCell ()

@property (nonatomic, weak) IBOutlet UIButton *answerToPostButton;
@property (nonatomic, weak) IBOutlet UIButton *answerToPostWithQuoteButton;
// Show answer to post button
@property (nonatomic, weak) IBOutlet UIButton *answerButton;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *separatorHeight;

@end

@implementation DVBActionsForPostTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    _separatorHeight.constant = 1.f / [UIScreen mainScreen].scale;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        self.backgroundColor = CELL_BACKGROUND_COLOR;
    }
}

- (void)prepareCellWithPostRepliesCount:(NSUInteger)postRepliesCount andIndex:(NSUInteger)index andDisableActionButton:(BOOL)disableActionButton
{
    NSString *answerButtonTitle;

    if (postRepliesCount > 0) {
        answerButtonTitle = [NSString stringWithFormat:@" %ld", (unsigned long)postRepliesCount];
        [_answerButton setEnabled:YES];
        [_answerButton setTitle:answerButtonTitle
                       forState:UIControlStateNormal];
        _answerButton.tag = index;
    }

    if (disableActionButton) {
        [_answerToPostButton setEnabled:NO];
        [_answerToPostWithQuoteButton setEnabled:NO];
    }
    else {
        _answerToPostButton.tag = index;
        _answerToPostWithQuoteButton.tag = index;
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    [_answerButton setEnabled:NO];
    [_answerButton setTitle:nil
                   forState:UIControlStateNormal];

    [_answerToPostButton setEnabled:YES];
    [_answerToPostWithQuoteButton setEnabled:YES];
}

@end
