//
//  UITableView+BottomRefreshControl.h
//  Showroom
//
//  Created by Nikolay Vlasov on 14.01.14.
//  Copyright (c) 2014 Nikolay Vlasov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (BottomRefreshControl)

@property (nonatomic) UIRefreshControl *bottomRefreshControl;

@end


@interface UIRefreshControl (BottomRefreshControl)

@property (nonatomic) CGFloat triggerVerticalOffset;

@end
