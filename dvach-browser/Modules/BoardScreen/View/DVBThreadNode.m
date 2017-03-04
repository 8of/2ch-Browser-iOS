//
//  DVBThreadNode.m
//  dvach-browser
//
//  Created by Andy on 16/11/16.
//  Copyright (c) 2016 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBThreadNode.h"
#import "DVBThread.h"
#import "DVBBoardStyler.h"

@interface DVBThreadNode() <ASNetworkImageNodeDelegate>

@property (strong, nonatomic) DVBThread *thread;
@property (strong, nonatomic) ASTextNode *postNode;
@property (strong, nonatomic) ASNetworkImageNode *mediaNode;
@property (strong, nonatomic) ASDisplayNode *borderNode;

@end

@implementation DVBThreadNode

#pragma mark - Lifecycle

- (instancetype)initWithThread:(DVBThread *)thread
{
    self = [super init];
    if (self) {
        _thread = thread;

        // Total border
        _borderNode = [[ASDisplayNode alloc] init];
        _borderNode.borderColor = [DVBBoardStyler borderColor];
        _borderNode.borderWidth = ONE_PIXEL;
        _borderNode.backgroundColor = [DVBBoardStyler threadCellInsideBackgroundColor];
        _borderNode.cornerRadius = [DVBBoardStyler cornerRadius];
        [self addSubnode:_borderNode];

        // Comment node
        _postNode = [[ASTextNode alloc] init];
        _postNode.attributedText = [self fromComment:thread.comment subject:thread.subject posts:thread.postsCount];
        _postNode.style.flexShrink = 1.0; //if name and username don't fit to cell width, allow username shrink
        _postNode.truncationMode = NSLineBreakByWordWrapping;
        _postNode.maximumNumberOfLines = 0;
        _postNode.textContainerInset = UIEdgeInsetsMake([DVBBoardStyler elementInset], [DVBBoardStyler elementInset], [DVBBoardStyler elementInset], [DVBBoardStyler elementInset]);
        [self addSubnode:_postNode];

        // Media
        _mediaNode = [[ASNetworkImageNode alloc] init];
        CGFloat mediaWidth = [DVBBoardStyler isWaitingForReview] ? 0 : [DVBBoardStyler mediaSize];
        _mediaNode.style.width = ASDimensionMakeWithPoints(mediaWidth);
        _mediaNode.style.height = ASDimensionMakeWithPoints([DVBBoardStyler mediaSize]);
        _mediaNode.URL = [NSURL URLWithString:_thread.thumbnail];
        _mediaNode.delegate = self;
        _mediaNode.imageModificationBlock = ^UIImage *(UIImage *image) {
            UIImage *modifiedImage;
            CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
            UIGraphicsBeginImageContextWithOptions(image.size, false, [[UIScreen mainScreen] scale]);
            [[UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:(UIRectCornerTopLeft|UIRectCornerBottomLeft) cornerRadii:CGSizeMake([DVBBoardStyler cornerRadius], [DVBBoardStyler cornerRadius])] addClip];
            [image drawInRect:rect];
            modifiedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return modifiedImage;
        };
        [self addSubnode:_mediaNode];
    }
    return self;
}

- (NSAttributedString *)fromComment:(NSString *)comment subject:(NSString *)subject posts:(NSNumber *)posts
{
  NSDictionary *textAttributes = @
  {
    NSFontAttributeName : [UIFont preferredFontForTextStyle: UIFontTextStyleSubheadline],
    NSForegroundColorAttributeName: [DVBBoardStyler textColor]
  };
  NSString *string = [NSString stringWithFormat:@"[%li] %@", (long)posts.integerValue, [self textFromSubject:subject andComment:comment]];
  return [[NSAttributedString alloc] initWithString:string attributes:textAttributes];
}

- (NSString *)textFromSubject:(NSString *)subject andComment:(NSString *)comment
{
  if (subject.length > 2 && comment.length > 2) {
    if ([[subject substringToIndex:2] isEqualToString:[comment substringToIndex:2]]) {
      return comment;
    }
  }
  return [NSString stringWithFormat:@"%@\n%@", subject, comment];
}

- (void)setHighlighted:(BOOL)highlighted
{
    self.backgroundColor = [DVBBoardStyler threadCellBackgroundColor];
    if (highlighted) {
        _borderNode.backgroundColor = [DVBBoardStyler threadCellBackgroundColor];
    } else {
        _borderNode.backgroundColor = [DVBBoardStyler threadCellInsideBackgroundColor];
    }
}

- (void)setSelected:(BOOL)selected
{
    self.backgroundColor = [DVBBoardStyler threadCellBackgroundColor];
    if (selected) {
        _borderNode.backgroundColor = [DVBBoardStyler threadCellBackgroundColor];
    } else {
        _borderNode.backgroundColor = [DVBBoardStyler threadCellInsideBackgroundColor];
    }
}

#pragma mark - ASDisplayNode

- (void)didLoad
{
    // enable highlighting now that self.layer has loaded -- see ASHighlightOverlayLayer.h
    self.layer.as_allowsHighlightDrawing = YES;
    [super didLoad];
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASStackLayoutSpec *horizontalStack = [ASStackLayoutSpec horizontalStackLayoutSpec];
    horizontalStack.direction          = ASStackLayoutDirectionHorizontal;
    horizontalStack.alignItems = ASStackLayoutAlignItemsStretch;
    horizontalStack.style.height = ASDimensionMakeWithPoints([DVBBoardStyler mediaSize]);
    [horizontalStack setChildren:@[_mediaNode, _postNode]];
    UIEdgeInsets insets = UIEdgeInsetsMake([DVBBoardStyler elementInset]/2+ONE_PIXEL, [DVBBoardStyler elementInset]+ONE_PIXEL, [DVBBoardStyler elementInset]/2+ONE_PIXEL, [DVBBoardStyler elementInset]+ONE_PIXEL);
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:insets
                                                  child:horizontalStack];
}

- (void)layout
{
    [super layout];
    // Manually layout the divider.
    _borderNode.frame = CGRectMake([DVBBoardStyler elementInset], [DVBBoardStyler elementInset]/2, self.calculatedSize.width - 2*[DVBBoardStyler elementInset], self.calculatedSize.height - [DVBBoardStyler elementInset]);
}

#pragma mark - ASNetworkImageNodeDelegate methods.

- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

@end
