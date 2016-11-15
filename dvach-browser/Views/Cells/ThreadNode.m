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

#define PostNodeDividerColor [UIColor lightGrayColor]

@interface ThreadNode() <ASNetworkImageNodeDelegate>

@property (strong, nonatomic) DVBThread *thread;
@property (strong, nonatomic) ASTextNode *postNode;
@property (strong, nonatomic) ASNetworkImageNode *mediaNode;
// @property (strong, nonatomic) ASTextNode *timeNode;
@property (strong, nonatomic) ASDisplayNode *divider;

@end

@implementation ThreadNode

#pragma mark - Lifecycle

- (instancetype)initWithThread:(DVBThread *)thread
{
    self = [super init];
    if (self) {
        _thread = thread;
        
        // Username node
        _postNode = [[ASTextNode alloc] init];
        _postNode.attributedText = [[NSAttributedString alloc] initWithString:thread.comment];
        _postNode.style.flexShrink = 1.0; //if name and username don't fit to cell width, allow username shrink
        _postNode.truncationMode = NSLineBreakByTruncatingTail;
        _postNode.maximumNumberOfLines = 0;
        [self addSubnode:_postNode];
        
        
        // Media
        _mediaNode = [[ASNetworkImageNode alloc] init];
        _mediaNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        _mediaNode.style.width = ASDimensionMakeWithPoints(44);
        _mediaNode.style.height = ASDimensionMakeWithPoints(44);
        _mediaNode.cornerRadius = 0.0;
        _mediaNode.URL = [NSURL URLWithString:_thread.thumbnail];
        _mediaNode.delegate = self;
        _mediaNode.imageModificationBlock = ^UIImage *(UIImage *image) {
            
            UIImage *modifiedImage;
            CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
            
            UIGraphicsBeginImageContextWithOptions(image.size, false, [[UIScreen mainScreen] scale]);
            
            [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:8.0] addClip];
            [image drawInRect:rect];
            modifiedImage = UIGraphicsGetImageFromCurrentImageContext();
            
            UIGraphicsEndImageContext();
            
            return modifiedImage;
            
        };
        [self addSubnode:_mediaNode];
        
        // Hairline cell separator
        _divider = [[ASDisplayNode alloc] init];
        [self updateDividerColor];
        [self addSubnode:_divider];
    }
    return self;
}

- (void)updateDividerColor
{
    /*
     * UITableViewCell traverses through all its descendant views and adjusts their background color accordingly
     * either to [UIColor clearColor], although potentially it could use the same color as the selection highlight itself.
     * After selection, the same trick is performed again in reverse, putting all the backgrounds back as they used to be.
     * But in our case, we don't want to have the background color disappearing so we reset it after highlighting or
     * selection is done.
     */
    _divider.backgroundColor = PostNodeDividerColor;
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
    horizontalStack.spacing            = 4.0;
    [horizontalStack setChildren:@[_mediaNode, _postNode]];
    
    return horizontalStack;
    
//    // Flexible spacer between username and time
//    ASLayoutSpec *spacer = [[ASLayoutSpec alloc] init];
//    spacer.style.flexGrow = 1.0;
//  
//    // NOTE: This inset is not actually required by the layout, but is an example of the upward propogation of layoutable
//    // properties.  Specifically, .flexGrow from the child is transferred to the inset spec so they can expand together.
//    // Without this capability, it would be required to set insetSpacer.flexGrow = 1.0;
//    ASInsetLayoutSpec *insetSpacer =
//    [ASInsetLayoutSpec
//     insetLayoutSpecWithInsets:UIEdgeInsetsMake(0, 0, 0, 0)
//     child:spacer];
//  
//    // Horizontal stack for name, username, via icon and time
////    NSMutableArray *layoutSpecChildren = [@[_nameNode, _usernameNode, insetSpacer] mutableCopy];
////    if (_post.via != 0) {
////        [layoutSpecChildren addObject:_viaNode];
////    }
////    [layoutSpecChildren addObject:_timeNode];
//    
////    ASStackLayoutSpec *nameStack =
////    [ASStackLayoutSpec
////     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
////     spacing:5.0
////     justifyContent:ASStackLayoutJustifyContentStart
////     alignItems:ASStackLayoutAlignItemsCenter
////     children:layoutSpecChildren];
////    nameStack.style.alignSelf = ASStackLayoutAlignSelfStretch;
//    
//    NSMutableArray *mainStackContent = [[NSMutableArray alloc] init];
////    [mainStackContent addObject:nameStack];
//    [mainStackContent addObject:_postNode];
//        
//    // Only add the media node if an image is present
//    if (_mediaNode.image != nil) {
//        CGFloat imageRatio = (_mediaNode.image != nil ? _mediaNode.image.size.height / _mediaNode.image.size.width : 0.5);
//        ASRatioLayoutSpec *imagePlace =
//        [ASRatioLayoutSpec
//         ratioLayoutSpecWithRatio:imageRatio
//         child:_mediaNode];
//        imagePlace.style.spacingAfter = 3.0;
//        imagePlace.style.spacingBefore = 3.0;
//        
//        [mainStackContent addObject:imagePlace];
//    }
//    
//    // Vertical spec of cell main content
//    ASStackLayoutSpec *contentSpec =
//    [ASStackLayoutSpec
//     stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
//     spacing:8.0
//     justifyContent:ASStackLayoutJustifyContentStart
//     alignItems:ASStackLayoutAlignItemsStretch
//     children:mainStackContent];
//    contentSpec.style.flexShrink = 1.0;
//    
//    // Horizontal spec for avatar
//    ASStackLayoutSpec *avatarContentSpec =
//    [ASStackLayoutSpec
//     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
//     spacing:8.0
//     justifyContent:ASStackLayoutJustifyContentStart
//     alignItems:ASStackLayoutAlignItemsStart
//     children:@[_mediaNode, contentSpec]];
//    
//    return [ASInsetLayoutSpec
//            insetLayoutSpecWithInsets:UIEdgeInsetsMake(10, 10, 10, 10)
//            child:avatarContentSpec];
    
}

- (void)layout
{
    [super layout];
    
    // Manually layout the divider.
    CGFloat pixelHeight = 1.0f / [[UIScreen mainScreen] scale];
    _divider.frame = CGRectMake(0.0f, 0.0f, self.calculatedSize.width, pixelHeight);
}

#pragma mark - ASCellNode

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self updateDividerColor];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self updateDividerColor];
}

#pragma mark - ASNetworkImageNodeDelegate methods.

- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

@end
