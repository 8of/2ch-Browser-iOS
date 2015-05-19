//
//  DVBAddPhotoIconImageView.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 19/05/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBAddPhotoIconImageView.h"

@implementation DVBAddPhotoIconImageView

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.image = [self.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self setTintColor:[UIColor whiteColor]];
}

@end
