//
//  DVBMediaOpener.h
//  dvach-browser
//
//  Created by Andy on 13/05/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVBMediaOpener : NSObject

- (instancetype)initWithViewController:(UIViewController *)viewController;

- (void)openMediaWithUrlString:(NSString *)fullUrlString andThumbImagesArray:(NSArray *)thumbImagesArray andFullImagesArray:(NSArray *)fullImagesArray;

@end

NS_ASSUME_NONNULL_END
