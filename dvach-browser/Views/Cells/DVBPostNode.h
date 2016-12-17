//
//  DVBPostNode.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 17/12/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DVBPostViewModel;

@interface DVBPostNode : ASCellNode

- (instancetype)initWithPost:(DVBPostViewModel *)post;

NS_ASSUME_NONNULL_END

@end
