//
//  DVBLoadingStatusView.h
//  dvach-browser
//
//  Created by Andy on 30/08/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DVBLoadingStatusView : UIView

typedef NS_ENUM(NSUInteger, DVBLoadingStatusViewStyle) {
    DVBLoadingStatusViewStyleLoading,
    DVBLoadingStatusViewStyleError
};

typedef NS_ENUM(NSUInteger, DVBLoadingStatusViewColor) {
    DVBLoadingStatusViewColorLight,
    DVBLoadingStatusViewColorDark
};

@property (nonatomic, assign, readonly) DVBLoadingStatusViewStyle loadingStatusViewStyle;

- (instancetype)initWithMessage:(NSString *)message andStyle:(DVBLoadingStatusViewStyle)style andColor:(DVBLoadingStatusViewColor)color;

@end
