//
//  DVBMarkupButton.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 27/04/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBMarkupButton.h"

@implementation DVBMarkupButton

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.layer.cornerRadius = 15;
    self.layer.borderWidth = 1;
    self.layer.borderColor = DVACH_COLOR_CG;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];

    if (highlighted) {
        self.layer.borderColor = DVACH_COLOR_HIGHLIGHTED_CG;
    }
    else {
        self.layer.borderColor = DVACH_COLOR_CG;
    }
}

@end
