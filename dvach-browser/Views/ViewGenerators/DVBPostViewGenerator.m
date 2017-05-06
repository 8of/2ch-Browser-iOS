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
  node.opaque = YES;
  node.borderColor = [DVBPostStyler borderColor];
  node.borderWidth = ONE_PIXEL;
  node.backgroundColor = [DVBPostStyler postCellInsideBackgroundColor];
  node.cornerRadius = [DVBPostStyler cornerRadius];

  return node;
}

+ (ASTextNode *)titleNode
{
  ASTextNode *node = [[ASTextNode alloc] init];
  node.backgroundColor = [DVBPostStyler postCellInsideBackgroundColor];
  node.truncationMode = NSLineBreakByTruncatingTail;
  node.maximumNumberOfLines = 1;
  return node;
}

+ (ASTextNode *)textNodeWithText:(NSAttributedString *)text
{
  ASTextNode *node = [[ASTextNode alloc] init];
  node.backgroundColor = [DVBPostStyler postCellInsideBackgroundColor];
  node.attributedText = text;
  node.truncationMode = NSLineBreakByWordWrapping;
  node.maximumNumberOfLines = 0;
  return node;
}

+ (ASNetworkImageNode *)mediaNodeWithURL:(NSString *)url isWebm:(BOOL)isWebm
{
  ASNetworkImageNode *node = [[ASNetworkImageNode alloc] init];
  CGFloat mediaWidth = [DVBPostStyler ageCheckNotPassed] ? 0 : [DVBPostStyler mediaSize];
  node.backgroundColor = [DVBPostStyler postCellInsideBackgroundColor];
  node.style.width = ASDimensionMakeWithPoints(mediaWidth);
  node.style.height = ASDimensionMakeWithPoints([DVBPostStyler mediaSize]);
  node.URL = [NSURL URLWithString:url];
  node.imageModificationBlock = ^UIImage *(UIImage *image) {
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGFloat scale = [[UIScreen mainScreen] scale];
    UIGraphicsBeginImageContextWithOptions(image.size, true, scale);

    // Fill background with color
    [[DVBPostStyler postCellInsideBackgroundColor] set];
    UIRectFill(CGRectMake(0, 0, rect.size.width, rect.size.height));

    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:[DVBPostStyler cornerRadius]] addClip];
    [image drawInRect:rect];
    if (isWebm) {
      UIImage *icon = [self webmIcon];
      CGFloat iconSide = icon.size.width * scale;
      CGFloat iconX = (rect.size.width - iconSide) / 2;
      CGFloat iconY = (rect.size.width - iconSide) / 2;
      CGRect iconRect = CGRectMake(iconX, iconY, iconSide, iconSide);
      [icon drawInRect:iconRect];
    }
    UIImage *modifiedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return modifiedImage;
  };
  return node;
}

+ (UIImage *)webmIcon
{
  return [UIImage imageNamed:@"Video"];
}

+ (ASButtonNode *)answerButton
{
  ASButtonNode *node = [self button];
  node.backgroundColor = [DVBPostStyler postCellInsideBackgroundColor];
  UIImage *image = [UIImage imageNamed:@"AnswerToPost"];
  [node setImage:image forState:UIControlStateNormal];
  node.style.height = ASDimensionMake(22);
  return node;
}

+ (ASButtonNode *)showAnswersButtonWithCount:(NSInteger)count
{
  ASButtonNode *node = [self button];
  node.backgroundColor = [DVBPostStyler postCellInsideBackgroundColor];
  NSString *title = [NSString stringWithFormat:@"%li", (long)count];
  UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
  [node setTitle:title
        withFont:font
       withColor:DVACH_COLOR
        forState:UIControlStateNormal];
  [node setTitle:title
        withFont:font
       withColor:DVACH_COLOR_HIGHLIGHTED
        forState:UIControlStateHighlighted];
  node.style.height = ASDimensionMake(22);
  node.style.minWidth = ASDimensionMake(33);
  node.contentEdgeInsets = UIEdgeInsetsMake(0, [DVBPostStyler elementInset], 0, [DVBPostStyler elementInset]);
  return node;
}

+ (ASButtonNode *)button
{
    ASButtonNode *node = [[ASButtonNode alloc] init];
    [node setTintColor:DVACH_COLOR];
    node.borderColor = DVACH_COLOR_CG;
    node.borderWidth = 1;
    node.cornerRadius = [DVBPostStyler cornerRadius];
    return node;
}

@end

NS_ASSUME_NONNULL_END
