//
//  DVBBoardTableViewCell.m
//  dvach-browser
//
//  Created by Mega on 13/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBBoardTableViewCell.h"

@interface DVBBoardTableViewCell ()

@property (nonatomic, weak) IBOutlet UIView *titleContainerView;
@property (nonatomic, weak) IBOutlet UIView *subtitleContainerView;

@property (nonatomic, weak) IBOutlet UILabel *title;
@property (nonatomic, weak) IBOutlet UILabel *subtitle;

@end

@implementation DVBBoardTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self resetUI];
}

- (void)prepareCellWithId:(NSString *)boardId andBoardName:(NSString *)boardName
{
    BOOL isBoardIdNotEmpty = ![boardId isEqualToString:@""];
    if (boardId && isBoardIdNotEmpty) {
        _title.text = boardId;
    }

    BOOL isNameNotEmpty = ![boardName isEqualToString:@""];
    if (boardName && isNameNotEmpty) {
        _subtitle.text = boardName;
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self resetUI];
}

- (void)resetUI
{
    [self setEditing:NO animated:NO];
    _title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        _titleContainerView.backgroundColor = CELL_BACKGROUND_COLOR;
        _subtitleContainerView.backgroundColor = CELL_BACKGROUND_COLOR;
        self.backgroundColor = CELL_BACKGROUND_COLOR;
        _title.textColor = CELL_TEXT_COLOR;
        _subtitle.textColor = CELL_TEXT_COLOR;
    } else {
        _titleContainerView.backgroundColor = [UIColor whiteColor];
        _subtitleContainerView.backgroundColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor clearColor];
        _title.textColor = [UIColor blackColor];
        _subtitle.textColor = [UIColor blackColor];
    }

    // Need additional checkup - or labels won't update itself on change
    _title.text = @" ";
    _subtitle.text = @" ";
}

@end
