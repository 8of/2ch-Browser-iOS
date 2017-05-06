//
//  DVBBrowserViewControllerBuilder.h
//  dvach-browser
//
//  Created by Andy on 18/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <MWPhotoBrowser/MWPhotoBrowser.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVBBrowserViewControllerBuilder : MWPhotoBrowser

@property (nonatomic, strong) UIPanGestureRecognizer *pan;

- (void)prepareWithIndex:(NSUInteger)index andThumbImagesArray:(NSArray *)thumbImagesArray andFullImagesArray:(NSArray *)fullImagesArray;

@end

NS_ASSUME_NONNULL_END
