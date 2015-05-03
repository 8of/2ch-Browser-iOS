//
//  DVBActionsForPostTableViewCell.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 03/05/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBActionsForPostTableViewCell.h"

@interface DVBActionsForPostTableViewCell ()

// Show answer to post button
@property (nonatomic, weak) IBOutlet UIButton *answerButton;
// Show action sheet for the post
@property (nonatomic, weak) IBOutlet UIButton *actionButton;

@end

@implementation DVBActionsForPostTableViewCell

- (void)prepareCellWithPostRepliesCount:(NSUInteger)postRepliesCount andIndex:(NSUInteger)index andDisableActionButton:(BOOL)disableActionButton
{
    // prepare Answer button
    _answerButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    NSString *answerButtonPretext = NSLocalizedString(@"Ответы", "Надпись на кнопке к посту для показа количества ответов и перехода к ним");
    NSString *answerButtonPretextNoAnswers = NSLocalizedString(@"Нет ответов", "Надпись на кнопке к посту для показа количества ответов и перехода к ним когда ответов нет");
    NSString *actionButtonPretext = NSLocalizedString(@"Действия", "Надпись на кнопке Действия если действия доступны");
    NSString *actionButtonPretextNoAnswers = NSLocalizedString(@"", "Надпись на кнопке Действия если действия не доступны");

    NSString *answerButtonTitle;
    NSString *actionButtonTitle;

    if (postRepliesCount > 0) {
        answerButtonTitle = [NSString stringWithFormat:@"%@ (%ld)", answerButtonPretext, (unsigned long)postRepliesCount];
    }
    else {
        answerButtonTitle = answerButtonPretextNoAnswers;
        [_answerButton setEnabled:NO];
    }

    if (disableActionButton) {
        actionButtonTitle = actionButtonPretextNoAnswers;
        [_actionButton setEnabled:NO];
    }
    else {
        actionButtonTitle = actionButtonPretext;
    }

    [_answerButton setTitle:answerButtonTitle forState:UIControlStateNormal];
    [_answerButton sizeToFit];
    _answerButton.tag = index;

    // prepare action button
    _actionButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [_actionButton setTitle:actionButtonTitle forState:UIControlStateNormal];
    [_actionButton sizeToFit];
    _actionButton.tag = index;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    [_answerButton setEnabled:YES];
    [_actionButton setEnabled:YES];

    [self.layer removeAllAnimations];
}

@end
