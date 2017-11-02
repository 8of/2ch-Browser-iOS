//
//  DVBPostNode.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 17/12/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBCommon.h"
#import "DVBConstants.h"
#import "DVBPostNode.h"
#import "DVBPostViewModel.h"
#import "DVBPostViewGenerator.h"
#import "DVBPostStyler.h"
#import "DVBMediaButtonNode.h"
#import "UrlNinja.h"
#import "DateFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVBPostNode() <ASNetworkImageNodeDelegate, ASTextNodeDelegate>

@property (nonatomic, weak, nullable) id<DVBThreadDelegate> delegate;

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) NSInteger timestamp;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) ASTextNode *titleNode;
@property (nonatomic, strong) ASTextNode *textNode;
@property (nonatomic, strong, nullable) ASStackLayoutSpec *mediaContainer;
@property (nonatomic, strong) ASDisplayNode *borderNode;
@property (nonatomic, strong) ASButtonNode *answerToPostButton;
@property (nonatomic, strong, nullable) ASButtonNode *answersButton;
@property (nonatomic, strong) ASStackLayoutSpec *buttonsContainer;
@property (nonatomic, strong, nullable) NSTimer *dageAgoTimer;

@end

@implementation DVBPostNode

#pragma mark - Lifecycle

- (void)dealloc
{
  [_dageAgoTimer invalidate];
  _dageAgoTimer = nil;
}

- (instancetype)initWithPost:(DVBPostViewModel *)post andDelegate:(id<DVBThreadDelegate>)delegate width:(CGFloat)width
{
    self = [super init];
    if (self) {
        self.opaque = YES;
        _delegate = delegate;
        _index = post.index;
        _timestamp = post.timestamp;
        // Total border
        _borderNode = [DVBPostViewGenerator borderNode];
        [self addSubnode:_borderNode];
        // Post num, title, time
        _title = post.title;
        _titleNode = [DVBPostViewGenerator titleNode];
        [self addSubnode:_titleNode];
        // Post text
        if (![post.text.string isEqualToString:@""]) {
            _textNode = [DVBPostViewGenerator textNodeWithText:post.text];
            _textNode.delegate = self;
            _textNode.userInteractionEnabled = YES;
            [self addSubnode:_textNode];
        }

        // Images
        if (post.thumbs.count > 0) {
            _mediaContainer = [self mediaRowsWithThumbs:post.thumbs fulls:post.pictures width:width];
        }

        // Buttons

        // Answers buttons
        _answerToPostButton = [DVBPostViewGenerator answerButton];
        [_answerToPostButton addTarget:self
                                action:@selector(answer:)
                      forControlEvents:ASControlNodeEventTouchUpInside];
        [self addSubnode:_answerToPostButton];

        if (post.repliesCount > 0) {
            _answersButton = [DVBPostViewGenerator showAnswersButtonWithCount:post.repliesCount];
            [_answersButton addTarget:self
                               action:@selector(showAnswers:)
                     forControlEvents:ASControlNodeEventTouchUpInside];
            [self addSubnode:_answersButton];
        }
        NSArray *buttonsChildren = _answersButton ? @[_answerToPostButton, _answersButton] : @[_answerToPostButton];
        _buttonsContainer = [ASStackLayoutSpec
                           stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                           spacing:[DVBPostStyler elementInset]
                           justifyContent:ASStackLayoutJustifyContentSpaceBetween
                           alignItems:ASStackLayoutAlignItemsStretch
                           children:buttonsChildren];
        [self updateTitle];
    }
    return self;
}

#pragma mark - View circle

- (void)didEnterVisibleState
{
  [super didEnterVisibleState];
  // Update post time in 1 sec
  _dageAgoTimer = [NSTimer scheduledTimerWithTimeInterval:1.
                                                   target:self
                                                 selector:@selector(updateTitle)
                                                 userInfo:nil
                                                  repeats:NO];
}

- (void)didExitVisibleState
{
  [super didExitVisibleState];
  [_dageAgoTimer invalidate];
  _dageAgoTimer = nil;
}

#pragma mark - Layout/sizing

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

- (ASStackLayoutSpec *)mediaRowsWithThumbs:(NSArray <NSString *> *)thumbs fulls:(NSArray <NSString *> *)fulls width:(CGFloat)width
{
  NSMutableArray <ASOverlayLayoutSpec *> *mediaNodesArray = [@[] mutableCopy];
  NSMutableArray <ASOverlayLayoutSpec *> *mediaNodesArraySecond = [@[] mutableCopy];
  weakify(self);
  [thumbs enumerateObjectsUsingBlock:^(NSString * _Nonnull mediaUrl, NSUInteger idx, BOOL * _Nonnull stop) {
    strongify(self);
    if (!self) { return; }

    BOOL isVideo = (fulls.count > idx) && ([fulls[idx] containsString:@".webm"] || [fulls[idx] containsString:@".mp4"]);
    ASNetworkImageNode *media = [DVBPostViewGenerator mediaNodeWithURL:mediaUrl isWebm:isVideo];
    DVBMediaButtonNode *mediaButton = [[DVBMediaButtonNode alloc] initWithURL:mediaUrl];
    [mediaButton addTarget:self
                    action:@selector(pictureTap:)
          forControlEvents:ASControlNodeEventTouchUpInside];
    media.delegate = self;
    [self addSubnode:media];
    [self addSubnode:mediaButton];
    ASOverlayLayoutSpec *overlay = [ASOverlayLayoutSpec overlayLayoutSpecWithChild:media overlay:mediaButton];
    CGFloat cellAndInsetWidth = [DVBPostStyler mediaSize] + [DVBPostStyler elementInset];
    CGFloat compare = width - 2 * [DVBPostStyler innerInset];
    if (idx * cellAndInsetWidth > compare) {
      [mediaNodesArraySecond addObject:overlay];
    } else {
      [mediaNodesArray addObject:overlay];
    }
  }];

  // Rows one below other
  NSMutableArray <ASStackLayoutSpec *> *rows = [@[] mutableCopy];
  [self addOverlayLayoutFrom:[mediaNodesArray copy] to:rows];
  [self addOverlayLayoutFrom:[mediaNodesArraySecond copy] to:rows];

  return [ASStackLayoutSpec
          stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
          spacing:[DVBPostStyler elementInset]
          justifyContent:ASStackLayoutJustifyContentStart
          alignItems:ASStackLayoutAlignItemsStart
          children:[rows copy]];
}

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

- (void)addOverlayLayoutFrom:(NSArray <ASOverlayLayoutSpec *> *)mediaNodesArray to:(NSMutableArray <ASStackLayoutSpec *> *)rows
{
  if (mediaNodesArray.count > 0) {
    // From left to right
    [rows addObject:[ASStackLayoutSpec
                     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                     spacing:[DVBPostStyler elementInset]
                     justifyContent:ASStackLayoutJustifyContentStart
                     alignItems:ASStackLayoutAlignItemsStart
                     children:mediaNodesArray]];
  }
}

/// Recalc title, assign it and schedule timer
- (void)updateTitle
{
  NSString *dateAgo = [DateFormatter dateFromTimestamp:_timestamp];
  NSString *fullTitle = [NSString stringWithFormat:@"%@%@", _title, dateAgo];
  NSDictionary *textAttributes = @
  {
    NSFontAttributeName : [UIFont preferredFontForTextStyle: UIFontTextStyleSubheadline],
  NSForegroundColorAttributeName: [DVBPostStyler textColor],
  NSBackgroundColorAttributeName: [DVBPostStyler postCellInsideBackgroundColor]
  };
  BOOL isTitleSame = [_titleNode.attributedText.string isEqualToString:fullTitle];
  if (isTitleSame) {
    return;
  }
  _titleNode.attributedText = [[NSAttributedString alloc] initWithString:fullTitle attributes:textAttributes];
}

#pragma mark - Actions

- (void)answer:(id)sender
{
  [self.delegate quotePostIndex:_index andText:nil];
}

- (void)pictureTap:(DVBMediaButtonNode *)sender
{
    [self.delegate openGalleryWIthUrl:sender.url];
}

- (void)showAnswers:(id)sender
{
    [self.delegate showAnswersFor:_index];
}

#pragma mark - ASNetworkImageNodeDelegate

- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

#pragma mark - ASTextNodeDelegate

- (void)textNode:(ASTextNode *)textNode tappedLinkAttribute:(NSString *)attribute value:(id)value atPoint:(CGPoint)point textRange:(NSRange)textRange
{
  if (!_delegate || ![value isKindOfClass:[NSURL class]]) {
    return;
  }
  NSURL *url = (NSURL *)value;
  UrlNinja *urlNinja = [UrlNinja unWithUrl:url];

  BOOL isLocalPostLink = [_delegate isLinkInternalWithLink:urlNinja];
  if (isLocalPostLink) {
    return;
  }
  [_delegate shareWithUrl:[url absoluteString]];
}

@end

NS_ASSUME_NONNULL_END
