//
//  DVBPostViewGenerator.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 17/12/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBPostViewGenerator.h"
#import "DVBPostStyler.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVBPostViewGenerator

+ (ASDisplayNode *)borderNode
{
    ASDisplayNode *node = [[ASDisplayNode alloc] init];
    node.borderColor = [DVBPostStyler borderColor];
    node.borderWidth = ONE_PIXEL;
    node.backgroundColor = [DVBPostStyler postCellInsideBackgroundColor];
    node.cornerRadius = [DVBPostStyler cornerRadius];

    return node;
}

+ (ASTextNode *)titleNodeWithText:(NSString *)text
{
    ASTextNode *node = [[ASTextNode alloc] init];
    NSDictionary *textAttributes = @
    {
        NSFontAttributeName : [UIFont preferredFontForTextStyle: UIFontTextStyleSubheadline],
        NSForegroundColorAttributeName: [DVBPostStyler textColor]
    };
    node.attributedText = [[NSAttributedString alloc] initWithString:text attributes:textAttributes];
    node.truncationMode = NSLineBreakByTruncatingTail;
    node.maximumNumberOfLines = 1;
    return node;
}

+ (ASTextNode *)textNodeWithText:(NSAttributedString *)text
{
    ASTextNode *node = [[ASTextNode alloc] init];
    node.attributedText = text;
    node.truncationMode = NSLineBreakByWordWrapping;
    node.maximumNumberOfLines = 0;
    return node;
}

+ (ASNetworkImageNode *)mediaNodeWithURL:(NSString *)url
{
    ASNetworkImageNode *node = [[ASNetworkImageNode alloc] init];
    CGFloat mediaWidth = [DVBPostStyler isWaitingForReview] ? 0 : [DVBPostStyler mediaSize];
    node.style.width = ASDimensionMakeWithPoints(mediaWidth);
    node.style.height = ASDimensionMakeWithPoints([DVBPostStyler mediaSize]);
    node.URL = [NSURL URLWithString:url];
    node.imageModificationBlock = ^UIImage *(UIImage *image) {
        UIImage *modifiedImage;
        CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
        UIGraphicsBeginImageContextWithOptions(image.size, false, [[UIScreen mainScreen] scale]);
        [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:2*[DVBPostStyler cornerRadius]] addClip];
        [image drawInRect:rect];
        modifiedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return modifiedImage;
    };
    return node;
}

@end

NS_ASSUME_NONNULL_END
