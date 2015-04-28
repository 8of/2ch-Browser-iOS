//
//  DVBPostPhotoContainerView.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 29/04/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBConstants.h"

#import "DVBPostPhotoContainerView.h"

@implementation DVBPostPhotoContainerView

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    [self setupCustomDesign];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupCustomDesign];
}

- (void)setupCustomDesign
{
    self.layer.backgroundColor = DVACH_COLOR_CG;
    self.layer.cornerRadius = 15.0f;
    self.clipsToBounds = YES;
}

@end
