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
    _title.text = boardId;
    _title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    
    _subtitle.text = name;
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
    _title.text = @"";
    [self setEditing:NO animated:NO];
}

@end