//
//  DVBThreadNode.h
//  dvach-browser
//
//  Created by Andy on 16/11/16.
//  Copyright (c) 2016 8of. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@class DVBThread;

@interface DVBThreadNode : ASCellNode

- (instancetype)initWithThread:(DVBThread *)thread;

@end
