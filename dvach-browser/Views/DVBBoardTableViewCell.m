//
//  DVBBoardTableViewCell.m
//  dvach-browser
//
//  Created by Mega on 13/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBBoardTableViewCell.h"

@interface DVBBoardTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *subtitle;

@end

@implementation DVBBoardTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)prepareCellWithBoardObject: (DVBBoard *)boardObject
{
    NSString *name = boardObject.name;
    NSString *boardId = boardObject.boardId;

    // need additional checkup - or title won't update itself on change
    _title.text = @" ";
    BOOL isBoardIdNotEmpty = ![boardId isEqualToString:@""];
    if (boardId && isBoardIdNotEmpty) {
        _title.text = boardId;
    }
    _title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];

    // need additional checkup - or subtitle won't update itself on change
    _subtitle.text = @" ";
    BOOL isNameNotEmpty = ![name isEqualToString:@""];
    if (name && isNameNotEmpty) {
        _subtitle.text = name;
    }
    _subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.contentView layoutIfNeeded];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self setEditing:NO animated:NO];
}

@end