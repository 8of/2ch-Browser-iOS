//
//  DVBMediaOpener.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 13/05/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DVBMediaOpener : NSObject

- (instancetype)initWithViewController:(UIViewController *)viewController;

- (void)openMediaWithUrlString:(NSString *)fullUrlString andThumbImagesArray:(NSArray *)thumbImagesArray andFullImagesArray:(NSArray *)fullImagesArray;

@end
