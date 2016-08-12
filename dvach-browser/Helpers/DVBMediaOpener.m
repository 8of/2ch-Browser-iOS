//
//  DVBMediaOpener.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 13/05/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBCommon.h"
#import "DVBConstants.h"

#import "DVBMediaOpener.h"
#import "DVBBrowserViewControllerBuilder.h"

#import "VDLPlaybackViewController.h"

@interface DVBMediaOpener ()

@property (nonatomic, strong) UIViewController *viewController;

@end

@implementation DVBMediaOpener

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Not enough info" reason:@"Use +[DVBMediaOpener initWith...]" userInfo:nil];

    return nil;
}

- (instancetype)initWithViewController:(UIViewController *)viewController
{
    self = [super init];

    if (self) {
        _viewController = viewController;
    }

    return self;
}

- (void)openMediaWithUrlString:(NSString *)fullUrlString andThumbImagesArray:(NSArray *)thumbImagesArray andFullImagesArray:(NSArray *)fullImagesArray
{
    // Check if cell have real image / webm video or just placeholder
    if (![fullUrlString isEqualToString:@""]) {
        // if contains .webm
        if ([fullUrlString rangeOfString:@".webm" options:NSCaseInsensitiveSearch].location != NSNotFound) {

            if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_INTERNAL_WEBM_PLAYER]) {
                // Because there are links with VLC in DB already
                NSURL *fullUrl = [NSURL URLWithString:[fullUrlString stringByReplacingOccurrencesOfString:@"vlc" withString:@"https"]];
                [self openWebMWithUrl:fullUrl];
            } else {
                NSURL *fullUrl = [NSURL URLWithString:fullUrlString];
                BOOL canOpenInVLC = [[UIApplication sharedApplication] canOpenURL:fullUrl];

                if (canOpenInVLC) {
                    [[UIApplication sharedApplication] openURL:fullUrl];
                }
                else {
                    [self problemAboutVlcToPrompt];
                }
            }
        }
        // if not
        else {
            [self createAndPushGalleryWithUrlString:fullUrlString
                                andThumbImagesArray:thumbImagesArray
                                 andFullImagesArray:fullImagesArray];
        }
    }
}

- (void)createAndPushGalleryWithUrlString:(NSString *)urlString andThumbImagesArray:(NSArray *)thumbImagesArray andFullImagesArray:(NSArray *)fullImagesArray
{
    NSUInteger indexForImageShowing = [fullImagesArray indexOfObject:urlString];

    if (indexForImageShowing < [fullImagesArray count]) {

        DVBBrowserViewControllerBuilder *galleryBrowser = [[DVBBrowserViewControllerBuilder alloc] initWithDelegate:nil];

        [galleryBrowser prepareWithIndex:indexForImageShowing
                     andThumbImagesArray:thumbImagesArray
                      andFullImagesArray:fullImagesArray];

        galleryBrowser.view.backgroundColor = [UIColor whiteColor];

        if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
            galleryBrowser.view.backgroundColor = [UIColor blackColor];
        }

        _viewController.navigationController.definesPresentationContext = YES;
        [galleryBrowser setModalPresentationStyle:UIModalPresentationOverCurrentContext];
        [_viewController.navigationController presentViewController:galleryBrowser
                                                           animated:YES
                                                         completion:nil];
    }
}

- (void)openWebMWithUrl:(NSURL *)url
{
    VDLPlaybackViewController *playbackViewController = [[VDLPlaybackViewController alloc] initWithNibName:nil bundle:nil];
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:playbackViewController];
    navCon.modalPresentationStyle = UIModalPresentationFullScreen;
    [playbackViewController playMediaFromURL:url];
    [_viewController presentViewController:navCon
                                  animated:YES
                                completion:nil];
}

/// NO VLC error prompt
- (void)problemAboutVlcToPrompt
{
    NSString *installVLCPrompt = NSLS(@"PROMPT_INSTALL_VLC");
    _viewController.navigationItem.prompt = installVLCPrompt;
    [self performSelector:@selector(clearPrompt)
               withObject:nil
               afterDelay:2.0];
}

/// Clear prompt from any status / error messages.
- (void)clearPrompt
{
    _viewController.navigationItem.prompt = nil;
}

@end
