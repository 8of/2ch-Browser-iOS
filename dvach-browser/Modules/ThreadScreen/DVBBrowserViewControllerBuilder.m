//
//  DVBBrowserViewControllerBuilder.m
//  dvach-browser
//
//  Created by Andy on 18/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBConstants.h"

#import "DVBBrowserViewControllerBuilder.h"

#import "DVBGalleryTransition.h"

static CGFloat const MIN_DURATION = .2;
static CGFloat const MAX_DURATION = .6;
static NSInteger const PROPORTION_TO_OVERPASS_TO_FINISH_TRANSITION = 5;

@interface DVBBrowserViewControllerBuilder () <MWPhotoBrowserDelegate, UIViewControllerTransitioningDelegate>

@property (nonatomic, assign) NSUInteger index;
// array of all post thumb images in thread
@property (nonatomic, strong) NSArray *thumbImagesArray;
// array of all post full images in thread
@property (nonatomic, strong) NSArray *fullImagesArray;

@property (nonatomic, strong) DVBGalleryTransition *transitionManager;

@end

@implementation DVBBrowserViewControllerBuilder

- (void)prepareWithIndex:(NSUInteger)index andThumbImagesArray:(NSArray *)thumbImagesArray andFullImagesArray:(NSArray *)fullImagesArray
{
    _index = index;

    _thumbImagesArray = thumbImagesArray;
    _fullImagesArray = fullImagesArray;

    [self removeAllWebmLinksFromThumbImagesArray:_thumbImagesArray
                              andFullImagesArray:_fullImagesArray];
    
    self.delegate = self;
    
    self.displayActionButton = YES;
    self.displayNavArrows = YES;
    self.displaySelectionButtons = NO;
    self.zoomPhotosToFill = NO;
    self.alwaysShowControls = NO;
    self.enableGrid = YES;
    self.startOnGrid = NO;
    
    // Set the current visible photo before displaying
    [self setCurrentPhotoIndex:_index];

    _transitionManager=[[DVBGalleryTransition alloc] init];
    self.transitioningDelegate = _transitionManager;

    _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.view addGestureRecognizer:_pan];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    return _fullImagesArray.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    if (index < _fullImagesArray.count) {
        NSURL *fullImageUrl = [NSURL URLWithString:_fullImagesArray[index]];
        MWPhoto *mwpPhoto = [MWPhoto photoWithURL:fullImageUrl];
        return mwpPhoto;
    }
    
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index
{
    if (index < _thumbImagesArray.count) {
        NSURL *thumbImageUrl = [NSURL URLWithString:_thumbImagesArray[index]];
        MWPhoto *mwpPhoto = [MWPhoto photoWithURL:thumbImageUrl];
        return mwpPhoto;
    }
    
    return nil;
}

- (void)removeAllWebmLinksFromThumbImagesArray:(NSArray *)thumbImagesArray andFullImagesArray:(NSArray *)fullImagesArray
{
    NSMutableArray *thumbImagesMutableArray = [thumbImagesArray mutableCopy];
    NSMutableArray *fullImagesMutableArray = [fullImagesArray mutableCopy];

    // start reverse loop because we need to delete objects more simplessly withour 'wrong indexes' erros
    NSUInteger currentItemWhenCheckForWebm = fullImagesArray.count - 1;

    for (NSString *photoPath in [fullImagesArray reverseObjectEnumerator]) {
        BOOL isWebmLink = ([photoPath rangeOfString:@"webm"].location != NSNotFound);

        if (isWebmLink) {
            [thumbImagesMutableArray removeObjectAtIndex:currentItemWhenCheckForWebm];
            [fullImagesMutableArray removeObjectAtIndex:currentItemWhenCheckForWebm];

            // decrease index of current photo to show first - because othervise we can show user the wrong one (if we delete photos with index between 0 and current index
            if (currentItemWhenCheckForWebm < _index) {
                _index--;
            }
        }
        currentItemWhenCheckForWebm--;
    }

    _thumbImagesArray = thumbImagesMutableArray;
    _fullImagesArray = fullImagesMutableArray;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        return UIStatusBarStyleLightContent;
    }

    return UIStatusBarStyleDefault;
}

#pragma mark - Dismiss Transition

- (void)pan:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self dismissViewControllerAnimated:YES completion:NULL];
        [recognizer setTranslation:CGPointZero inView:self.view.superview];
        [_transitionManager updateInteractiveTransition:0];
        return;
    }

    CGFloat percentage = [recognizer translationInView:self.view.superview].y / self.view.superview.bounds.size.height;

    [_transitionManager updateInteractiveTransition:percentage];

    if (recognizer.state == UIGestureRecognizerStateEnded) {

        CGFloat velocityY = [recognizer velocityInView:recognizer.view.superview].y;

        // If moved up but not so far
        BOOL isBadDistanceUp = (velocityY < 0) && (-recognizer.view.frame.origin.y < self.view.bounds.size.height / PROPORTION_TO_OVERPASS_TO_FINISH_TRANSITION);

        // If moved down but not so far
        BOOL isBadDistanceDown = (velocityY > 0) && (recognizer.view.frame.origin.y < self.view.bounds.size.height / PROPORTION_TO_OVERPASS_TO_FINISH_TRANSITION);

        BOOL cancel = isBadDistanceUp || isBadDistanceDown;

        CGFloat points = cancel ? recognizer.view.frame.origin.y : self.view.superview.bounds.size.height-recognizer.view.frame.origin.y;
        NSTimeInterval duration = points / velocityY;

        if (duration < MIN_DURATION) {
            duration = MIN_DURATION;
        } else if (duration > MAX_DURATION) {
            duration = MAX_DURATION;
        }

        if (cancel) {
            [_transitionManager cancelInteractiveTransitionWithDuration:duration];
        } else {
            BOOL toTop = NO;
            if (velocityY < 0) {
                toTop = YES;
            }

            [_transitionManager finishInteractiveTransitionWithDuration:duration andToTop:toTop];
        }

    } else if (recognizer.state == UIGestureRecognizerStateFailed) {
        [_transitionManager cancelInteractiveTransitionWithDuration:.35];
    }
}

@end
