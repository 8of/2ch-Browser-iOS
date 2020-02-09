//
//  DVBCreatePostScrollView.m
//  dvach-browser
//
//  Created by Andy on 13/06/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBCreatePostScrollView.h"

@implementation DVBCreatePostScrollView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    if ( [view isKindOfClass:[UIButton class]] ) {
        return YES;
    }

    return [super touchesShouldCancelInContentView:view];
}

@end
