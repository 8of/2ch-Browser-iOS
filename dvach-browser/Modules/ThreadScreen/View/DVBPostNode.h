//
//  DVBPostNode.h
//  dvach-browser
//
//  Created by Andy on 17/12/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

#import "DVBThreadDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class DVBPostViewModel;

@interface DVBPostNode : ASCellNode

- (instancetype)initWithPost:(DVBPostViewModel *)post andDelegate:(id<DVBThreadDelegate>)delegate width:(CGFloat)width;

NS_ASSUME_NONNULL_END

@end
