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
#import "DVBBoardStyler.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVBPostNode() <ASNetworkImageNodeDelegate>

@property (nonatomic, strong) ASTextNode *titleNode;
@property (nonatomic, strong) ASTextNode *textNode;
// @property (nonatomic, strong) ASNetworkImageNode *mediaNode;
@property (nonatomic, strong) ASDisplayNode *borderNode;

@end

@implementation DVBPostNode

#pragma mark - Lifecycle

- (instancetype)initWithPost:(DVBPostViewModel *)post
{
    self = [super init];
    if (self) {

        // Total border
        _borderNode = [[ASDisplayNode alloc] init];
        _borderNode.borderColor = [DVBBoardStyler borderColor];
        _borderNode.borderWidth = ONE_PIXEL;
        _borderNode.backgroundColor = [DVBBoardStyler threadCellInsideBackgroundColor];
        _borderNode.cornerRadius = [DVBBoardStyler cornerRadius];
        [self addSubnode:_borderNode];

    }
    return self;
}

- (void)layout
{
    [super layout];
    // Manually layout the divider.
    _borderNode.frame = CGRectMake([DVBBoardStyler elementInset], [DVBBoardStyler elementInset]/2, self.calculatedSize.width - 2*[DVBBoardStyler elementInset], self.calculatedSize.height - [DVBBoardStyler elementInset]);
}

@end

NS_ASSUME_NONNULL_END
