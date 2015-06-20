//
//  MPTransition.m
//  VCtransition
//
//  Created by Alex Manzella on 29/09/14.
//  Copyright (c) 2014 mpow. All rights reserved.
//

#import "MPTransition.h"

@implementation MPTransition

#pragma mark - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self;
}

- (id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator
{
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{

    }completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)animationEnded:(BOOL)transitionCompleted
{
}

#pragma mark - UIViewControllerInteractiveTransitioning

- (void)startInteractiveTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    self.transitionContext = transitionContext;
    
    UIView *inView = [transitionContext containerView];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    toViewController.view.layer.zPosition = -1;
    [inView.superview addSubview:toViewController.view];
}

#pragma mark - UIPercentDrivenInteractiveTransition

- (void)updateInteractiveTransition:(CGFloat)percentComplete
{
    if (percentComplete < -1) {
        percentComplete = -1;
    } else if (percentComplete > 1) {
        percentComplete = 1;
    }
    
    UIViewController *toViewController = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    CGRect frame = toViewController.view.frame;
    frame.origin.y = toViewController.view.bounds.size.height * percentComplete;
    fromViewController.view.frame = frame;
}

- (void)cancelInteractiveTransitionWithDuration:(CGFloat)duration
{
    UIViewController *toViewController = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         CGRect frame = toViewController.view.frame;
                         fromViewController.view.frame = frame;
                     } completion:^(BOOL finished) {
                         [toViewController.view removeFromSuperview];
                         [self.transitionContext cancelInteractiveTransition];
                         [self.transitionContext completeTransition:NO];
                         self.transitionContext = nil;
                     }];

    [self cancelInteractiveTransition];
}

- (void)finishInteractiveTransitionWithDuration:(CGFloat)duration andToTop:(BOOL)toTop
{
    UIViewController *toViewController = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         CGRect frame = toViewController.view.frame;
                         if (toTop) {
                             frame.origin.y = - toViewController.view.bounds.size.height;
                         } else {
                             frame.origin.y = toViewController.view.bounds.size.height;
                         }

                         fromViewController.view.frame = frame;
                     } completion:^(BOOL finished) {
                         [fromViewController.view removeFromSuperview];
                         [self.transitionContext completeTransition:YES];
                         self.transitionContext = nil;
                     }];
    
    [self finishInteractiveTransition];
}

@end
