//
//  DVBBoardTableViewCell.m
//  dvach-browser
//
//  Created by Mega on 13/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBConstants.h"

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

    _title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        _titleContainerView.backgroundColor = CELL_BACKGROUND_COLOR;
        _subtitleContainerView.backgroundColor = CELL_BACKGROUND_COLOR;
        self.backgroundColor = CELL_BACKGROUND_COLOR;

        [_title setTextColor:CELL_TEXT_COLOR];
        [_subtitle setTextColor:CELL_TEXT_COLOR];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)prepareCellWithId:(NSString *)boardId andBoardName:(NSString *)boardName
{
    // need additional checkup - or title won't update itself on change
    _title.text = @" ";
    BOOL isBoardIdNotEmpty = ![boardId isEqualToString:@""];
    if (boardId && isBoardIdNotEmpty) {
        _title.text = boardId;
    }

    // need additional checkup - or subtitle won't update itself on change
    _subtitle.text = @" ";
    BOOL isNameNotEmpty = ![boardName isEqualToString:@""];
    if (boardName && isNameNotEmpty) {
        _subtitle.text = boardName;
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self setEditing:NO animated:NO];
}

@end
