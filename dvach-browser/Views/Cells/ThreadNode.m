//
//  PostNode.m
//  Sample
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "ThreadNode.h"
#import "DVBThread.h"


@interface ThreadNode() <ASNetworkImageNodeDelegate>

@property (strong, nonatomic) DVBThread *thread;
@property (strong, nonatomic) ASTextNode *postNode;
@property (strong, nonatomic) ASNetworkImageNode *mediaNode;
@property (strong, nonatomic) ASDisplayNode *borderNode;

@end

@implementation ThreadNode

#pragma mark - Lifecycle

- (instancetype)initWithThread:(DVBThread *)thread
{
    self = [super init];
    if (self) {
        _thread = thread;

        // Total border
        _borderNode = [[ASDisplayNode alloc] init];
        _borderNode.borderColor = [[UIColor lightGrayColor] CGColor];
        _borderNode.borderWidth = 1.0f / [[UIScreen mainScreen] scale];
        _borderNode.backgroundColor = [UIColor whiteColor];
        _borderNode.cornerRadius = 3.0;
        [self addSubnode:_borderNode];

        // Comment node
        _postNode = [[ASTextNode alloc] init];
        _postNode.attributedText = [[NSAttributedString alloc] initWithString:thread.comment];
        _postNode.style.flexShrink = 1.0; //if name and username don't fit to cell width, allow username shrink
        _postNode.truncationMode = NSLineBreakByWordWrapping;
        _postNode.maximumNumberOfLines = 0;
        _postNode.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
        [self addSubnode:_postNode];

        // Media
        _mediaNode = [[ASNetworkImageNode alloc] init];
        _mediaNode.style.width = ASDimensionMakeWithPoints(80);
        _mediaNode.style.height = ASDimensionMakeWithPoints(80);
        _mediaNode.URL = [NSURL URLWithString:_thread.thumbnail];
        _mediaNode.delegate = self;
        _mediaNode.imageModificationBlock = ^UIImage *(UIImage *image) {
            UIImage *modifiedImage;
            CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
            UIGraphicsBeginImageContextWithOptions(image.size, false, [[UIScreen mainScreen] scale]);
            [[UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:(UIRectCornerTopLeft|UIRectCornerBottomLeft) cornerRadii:CGSizeMake(6, 6)] addClip];
            [image drawInRect:rect];
            modifiedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return modifiedImage;
        };
        [self addSubnode:_mediaNode];
    }
    return self;
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
    horizontalStack.style.height = ASDimensionMakeWithPoints(80);
    [horizontalStack setChildren:@[_mediaNode, _postNode]];
    CGFloat onePixel = 1.0f / [[UIScreen mainScreen] scale];
    UIEdgeInsets insets = UIEdgeInsetsMake(5+onePixel, 10+onePixel, 5+onePixel, 10+onePixel);
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:insets
                                                  child:horizontalStack];
}

- (void)layout
{
    [super layout];
    
    // Manually layout the divider.
    _borderNode.frame = CGRectMake(10.0f, 5.0f, self.calculatedSize.width - 20, self.calculatedSize.height - 10);

}

#pragma mark - ASNetworkImageNodeDelegate methods.

- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

@end
