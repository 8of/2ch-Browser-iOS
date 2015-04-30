//
//  UIImage+DVBImageExtention.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 30/04/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

// DO NOT MESS WITH RUNTIME!
#import <objc/runtime.h>

#import "UIImage+DVBImageExtention.h"

@implementation UIImage (DVBImageExtention)

@dynamic imageExtention;

- (void)setImageExtention:(NSString *)imageExtention
{
    objc_setAssociatedObject(self, @selector(imageExtention), imageExtention, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)imageExtention
{
    return objc_getAssociatedObject(self, @selector(imageExtention));
}

@end
