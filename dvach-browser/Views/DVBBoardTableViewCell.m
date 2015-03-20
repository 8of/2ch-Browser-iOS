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

@end

@implementation DVBBoardTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)prepareCellWithBoardObject: (DVBBoardObj *)boardObject
{
    NSString *name = boardObject.name;
    NSString *boardId = boardObject.boardId;
    NSString *titleFullString = [NSString stringWithFormat:@"%@ - /%@/",name,boardId];
    _title.text = titleFullString;
    _title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.contentView layoutIfNeeded];

}

- (void)prepareForReuse
{
    _title.text = @"";
}

@end