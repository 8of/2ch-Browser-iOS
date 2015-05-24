//
//  DVBTitleForPostTableViewCell.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 23/05/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBConstants.h"

#import "DVBTitleForPostTableViewCell.h"

@interface DVBTitleForPostTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;


@end

@implementation DVBTitleForPostTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _titleLabel.layer.masksToBounds = NO;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_LITTLE_BODY_FONT]) {
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    }

    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        self.backgroundColor = CELL_BACKGROUND_COLOR;
        [_titleLabel setTextColor:CELL_TEXT_COLOR];
    }
}

- (void)prepareCellWithTitle:(NSString *)title
{
    _titleLabel.text = title;
}

@end
