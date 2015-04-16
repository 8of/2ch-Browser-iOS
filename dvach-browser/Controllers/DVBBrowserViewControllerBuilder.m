//
//  DVBBrowserViewControllerBuilder.m
//  dvach-browser
//
//  Created by Andy on 18/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBBrowserViewControllerBuilder.h"

@interface DVBBrowserViewControllerBuilder () <MWPhotoBrowserDelegate>

// array of all post thumb images in thread
@property (nonatomic, strong) NSArray *thumbImagesArray;
// array of all post full images in thread
@property (nonatomic, strong) NSArray *fullImagesArray;

@end

@implementation DVBBrowserViewControllerBuilder

- (void)prepareWithIndex:(NSUInteger)index andThumbImagesArray:(NSArray *)thumbImagesArray andFullImagesArray:(NSArray *)fullImagesArray {

    _thumbImagesArray = thumbImagesArray;
    _fullImagesArray = fullImagesArray;

    [self removeAllWebmLinksFromThumbImagesArray:_thumbImagesArray andFullImagesArray:_fullImagesArray];
    
    self.delegate = self;
    
    self.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    self.displayNavArrows = YES; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    self.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    self.zoomPhotosToFill = NO; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    self.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    self.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    self.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    
    // Set the current visible photo before displaying
    [self setCurrentPhotoIndex:_index];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    return [_fullImagesArray count];
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
/**
 *  Не очень нравится идея перезаписывать respondsToSelector
 *  Но есть свои плюсы, например система не тратит ресурсы на вызов и просчёт через heightForRowAtIndexPath
 */
- (void)removeAllWebmLinksFromThumbImagesArray:(NSArray *)thumbImagesArray andFullImagesArray:(NSArray *)fullImagesArray
{
    NSMutableArray *thumbImagesMutableArray = [thumbImagesArray mutableCopy];
    NSMutableArray *fullImagesMutableArray = [fullImagesArray mutableCopy];

    NSUInteger currentItemWhenCheckForWebm = 0;

    for (NSString *photoPath in fullImagesArray) {
        BOOL isWebmLink = [photoPath rangeOfString:@"webm"].location!=NSNotFound;

        if (isWebmLink) {
            [thumbImagesMutableArray removeObjectAtIndex:currentItemWhenCheckForWebm];
            [fullImagesMutableArray removeObjectAtIndex:currentItemWhenCheckForWebm];
        }
        currentItemWhenCheckForWebm++;
    }

    _thumbImagesArray = thumbImagesMutableArray;
    _fullImagesArray = fullImagesMutableArray;
}

@end
