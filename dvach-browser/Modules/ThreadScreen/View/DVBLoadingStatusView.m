//
//  DVBLoadingStatusView.m
//  dvach-browser
//
//  Created by Andy on 30/08/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBLoadingStatusView.h"

static NSString * const IMAGE_NAME_LOAD = @"LoadingStatus_1";
static NSString * const IMAGE_NAME_ERROR = @"LoadingStatusError";

@interface DVBLoadingStatusView ()

@property (nonatomic, strong) IBOutlet UIImageView *statusIcon;
@property (nonatomic, strong) IBOutlet UILabel *statusLabel;

@end

@implementation DVBLoadingStatusView

- (instancetype)initWithMessage:(NSString *)message andStyle:(DVBLoadingStatusViewStyle)style andColor:(DVBLoadingStatusViewColor)color
{
    NSString *nibName = NSStringFromClass(self.class);
    self = [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] lastObject];

    _statusLabel.text = message;
    _loadingStatusViewStyle = style;

    switch (style) {
        case DVBLoadingStatusViewStyleLoading:
        {
            _statusIcon.image = [[UIImage imageNamed:IMAGE_NAME_LOAD] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        }

        case DVBLoadingStatusViewStyleError:
        {
            _statusIcon.image = [[UIImage imageNamed:IMAGE_NAME_ERROR]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        }

        default:
            break;
    }

    switch (color) {
        case DVBLoadingStatusViewColorLight:
        {
            _statusLabel.textColor = [UIColor grayColor];
            _statusIcon.tintColor = [UIColor grayColor];
            break;
        }

        case DVBLoadingStatusViewColorDark:
        {
            _statusLabel.textColor = [UIColor whiteColor];
            _statusIcon.tintColor = [UIColor whiteColor];
            break;
        }

        default:
            break;
    }

    return self;
}

@end
