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

@property (nonatomic, weak, nullable) id<DVBThreadDelegate> delegate;

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

- (instancetype)initWithPost:(DVBPostViewModel *)post andDelegate:(id<DVBThreadDelegate>)delegate
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        // Total border
        _borderNode = [DVBPostViewGenerator borderNode];
        [self addSubnode:_borderNode];
        // Post num, title, time
        _titleNode = [DVBPostViewGenerator titleNodeWithText:post.title];
        [self addSubnode:_titleNode];
        // Post text
        if (![post.text.string isEqualToString:@""]) {
            _textNode = [DVBPostViewGenerator textNodeWithText:post.text];
            [self addSubnode:_textNode];
        }

        // Images
        if (post.thumbs.count > 0) {
            NSMutableArray <ASOverlayLayoutSpec *> *mediaNodesArray = [@[] mutableCopy];
            for (NSString *mediaUrl in post.thumbs) {
                ASNetworkImageNode *media = [DVBPostViewGenerator mediaNodeWithURL:mediaUrl];
                ASButtonNode *mediaButton = [[ASButtonNode alloc] init];
                [mediaButton addTarget:self
                                action:@selector(pictureTap:)
                      forControlEvents:ASControlNodeEventTouchUpInside];
                media.delegate = self;
                [self addSubnode:media];
                [self addSubnode:mediaButton];
                ASOverlayLayoutSpec *overlay = [ASOverlayLayoutSpec overlayLayoutSpecWithChild:media overlay:mediaButton];
                [mediaNodesArray addObject:overlay];
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
        [_answerToPostButton addTarget:self
                                action:@selector(answer:)
                      forControlEvents:ASControlNodeEventTouchUpInside];
        [self addSubnode:_answerToPostButton];
        _answerToPostWithQuoteButton = [DVBPostViewGenerator answerWithQuoteButton];
        [_answerToPostWithQuoteButton addTarget:self
                                         action:@selector(answerWithQuote:)
                               forControlEvents:ASControlNodeEventTouchUpInside];
        [self addSubnode:_answerToPostWithQuoteButton];

        if (post.repliesCount > 0) {
            _answersButton = [DVBPostViewGenerator showAnswersButtonWithCount:post.repliesCount];
            [_answersButton addTarget:self
                               action:@selector(showAnswers:)
                     forControlEvents:ASControlNodeEventTouchUpInside];
            [self addSubnode:_answersButton];
        }
        ASStackLayoutSpec *leftButtonsContainer = [ASStackLayoutSpec
                                                   stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                                   spacing:[DVBPostStyler elementInset]
                                                   justifyContent:ASStackLayoutJustifyContentStart
                                                   alignItems:ASStackLayoutAlignItemsStart
                                                   children:@[_answerToPostButton, _answerToPostWithQuoteButton]];
        NSArray *buttonsChildren = _answersButton ? @[leftButtonsContainer, _answersButton] : @[leftButtonsContainer];
        _buttonsContainer = [ASStackLayoutSpec
                           stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                           spacing:[DVBPostStyler elementInset]
                           justifyContent:ASStackLayoutJustifyContentSpaceBetween
                           alignItems:ASStackLayoutAlignItemsStretch
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
    verticalStack.children = [self mainStackChildren];
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

#pragma mark - Private

- (NSArray<id<ASLayoutElement>> *)mainStackChildren
{
    NSMutableArray *vertStackChildren = [@[_titleNode] mutableCopy];
    if (_mediaContainer) {
        [vertStackChildren addObject:_mediaContainer];
    }
    if (_textNode) {
        [vertStackChildren addObject:_textNode];
    }
    [vertStackChildren addObject:_buttonsContainer];
    return [vertStackChildren copy];
}

- (void)answer:(id)sender
{

}

- (void)answerWithQuote:(id)sender
{

}

- (void)pictureTap:(id)sender
{

}

- (void)showAnswers:(id)sender
{

}

#pragma mark - ASNetworkImageNodeDelegate methods.

- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

@end

NS_ASSUME_NONNULL_END
