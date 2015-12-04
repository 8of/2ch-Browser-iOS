//
//  UIImage+DVBOpaqueImage.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 11/11/15.
//  Copyright © 2015 8of. All rights reserved.
//

#import "UIImage+DVBOpaqueImage.h"

@implementation UIImage (DVBOpaqueImage)

+ (UIImage *)optimizedImageFromImage:(UIImage *)image
{
    CGSize imageSize = image.size;
    UIGraphicsBeginImageContextWithOptions(imageSize, YES, [[UIScreen mainScreen] scale]);
    [image drawInRect: CGRectMake(0, 0, imageSize.width, imageSize.height)];
    UIImage *optimizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return optimizedImage;
}

@end
