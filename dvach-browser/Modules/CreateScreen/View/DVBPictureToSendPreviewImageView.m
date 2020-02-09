//
//  DVBPictureToSendPreviewImageView.m
//  dvach-browser
//
//  Created by Andy on 19/05/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBPictureToSendPreviewImageView.h"

@implementation DVBPictureToSendPreviewImageView

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.contentMode = UIViewContentModeScaleAspectFill;
    self.clipsToBounds = YES;
}

@end
