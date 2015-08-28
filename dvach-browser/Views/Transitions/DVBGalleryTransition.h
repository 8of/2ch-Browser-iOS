//
//  DVBGalleryTransition.h
//  VCtransition
//
//  Created by Andrey Konstantinov on 09/07/14.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DVBGalleryTransition : UIPercentDrivenInteractiveTransition<UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning, UIViewControllerTransitioningDelegate>

@property (nonatomic, readwrite) id <UIViewControllerContextTransitioning> transitionContext;

- (void)cancelInteractiveTransitionWithDuration:(CGFloat)duration;
- (void)finishInteractiveTransitionWithDuration:(CGFloat)duration andToTop:(BOOL)toTop;

@end
