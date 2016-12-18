//
//  DVBPostNode.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 17/12/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBPostNode.h"
#import "DVBPostViewModel.h"
#import "DVBPostViewGenerator.h"
#import "DVBPostStyler.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVBPostNode() <ASNetworkImageNodeDelegate>

@property (nonatomic, strong) ASTextNode *titleNode;
@property (nonatomic, strong) ASTextNode *textNode;
@property (nonatomic, strong) ASDisplayNode *mediaNodeContainer;
@property (nonatomic, strong) ASDisplayNode *borderNode;

@end

@implementation DVBPostNode

#pragma mark - Lifecycle

- (instancetype)initWithPost:(DVBPostViewModel *)post
{
    self = [super init];
    if (self) {
        // Total border
        _borderNode = [DVBPostViewGenerator borderNode];
        [self addSubnode:_borderNode];
        // Post num, title, time
        _titleNode = [DVBPostViewGenerator titleNodeWithText:post.title];
        [self addSubnode:_titleNode];
        // Post text
        _textNode = [DVBPostViewGenerator textNodeWithText:post.text];
        [self addSubnode:_textNode];
        // Images
        _mediaNodeContainer = [[ASDisplayNode alloc] init];
        for (NSString *mediaUrl in post.thumbs) {
            ASNetworkImageNode *media = [DVBPostViewGenerator mediaNodeWithURL:mediaUrl];
            media.delegate = self;
            [_mediaNodeContainer addSubnode:media];
        }

    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASStackLayoutSpec *verticalStack = [ASStackLayoutSpec horizontalStackLayoutSpec];
    verticalStack.direction          = ASStackLayoutDirectionVertical;
    verticalStack.alignItems = ASStackLayoutAlignItemsStretch;
    [verticalStack setChildren:@[_titleNode, _textNode]];
    UIEdgeInsets insets = UIEdgeInsetsMake([DVBPostStyler elementInset], [DVBPostStyler elementInset], [DVBPostStyler elementInset], [DVBPostStyler elementInset]);
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:insets
                                                  child:verticalStack];
}

- (void)layout
{
    [super layout];
    // Manually layout the divider.
    _borderNode.frame = CGRectMake([DVBPostStyler elementInset], [DVBPostStyler elementInset]/2, self.calculatedSize.width - 2*[DVBPostStyler elementInset], self.calculatedSize.height - [DVBPostStyler elementInset]);
}

#pragma mark - ASNetworkImageNodeDelegate methods.

- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

@end

NS_ASSUME_NONNULL_END
