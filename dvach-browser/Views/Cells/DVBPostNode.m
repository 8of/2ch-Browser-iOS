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
@property (nonatomic, strong, nullable) ASStackLayoutSpec *mediaContainer;
@property (nonatomic, strong) ASDisplayNode *borderNode;
@property (nonatomic, strong) ASButtonNode *answerToPostButton;
@property (nonatomic, strong) ASButtonNode *answerToPostWithQuoteButton;
@property (nonatomic, strong, nullable) ASButtonNode *answersButton;
@property (nonatomic, strong) ASStackLayoutSpec *buttonsContainer;

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
        if (post.thumbs.count > 0) {
            NSMutableArray <ASNetworkImageNode *> *mediaNodesArray = [@[] mutableCopy];
            for (NSString *mediaUrl in post.thumbs) {
                ASNetworkImageNode *media = [DVBPostViewGenerator mediaNodeWithURL:mediaUrl];
                media.delegate = self;
                [mediaNodesArray addObject:media];
                [self addSubnode:media];
            }
            _mediaContainer = [ASStackLayoutSpec
                               stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                               spacing:[DVBPostStyler elementInset]
                               justifyContent:ASStackLayoutJustifyContentStart
                               alignItems:ASStackLayoutAlignItemsStart
                               children:[mediaNodesArray copy]];
        }

        // Buttons

        // Answers buttons
        _answerToPostButton = [DVBPostViewGenerator answerButton];
        [self addSubnode:_answerToPostButton];
        _answerToPostWithQuoteButton = [DVBPostViewGenerator answerWithQuoteButton];
        [self addSubnode:_answerToPostWithQuoteButton];

        if (post.repliesCount > 0) {
            _answersButton = [DVBPostViewGenerator showAnswersButtonWithCount:post.repliesCount];
            [self addSubnode:_answersButton];
        }
        NSArray *buttonsChildren = _answersButton ? @[_answerToPostButton, _answerToPostWithQuoteButton, _answersButton] : @[_answerToPostButton, _answerToPostWithQuoteButton];
        _buttonsContainer = [ASStackLayoutSpec
                           stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                           spacing:[DVBPostStyler elementInset]
                           justifyContent:ASStackLayoutJustifyContentStart
                           alignItems:ASStackLayoutAlignItemsStart
                           children:buttonsChildren];

    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASStackLayoutSpec *verticalStack = [ASStackLayoutSpec horizontalStackLayoutSpec];
    verticalStack.direction          = ASStackLayoutDirectionVertical;
    verticalStack.alignItems = ASStackLayoutAlignItemsStretch;
    verticalStack.spacing = [DVBPostStyler elementInset];
    NSArray *vertStackChildren = _mediaContainer ? @[_mediaContainer, _titleNode, _textNode, _buttonsContainer] : @[_titleNode, _textNode, _buttonsContainer];
    verticalStack.children = vertStackChildren;
    CGFloat topInset = 1.5 * [DVBPostStyler elementInset];
    UIEdgeInsets insets = UIEdgeInsetsMake(topInset, [DVBPostStyler innerInset], topInset, [DVBPostStyler innerInset]);
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
