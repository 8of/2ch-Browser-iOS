//
//  DVBMediaOpener.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 13/05/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBMediaOpener.h"
#import "DVBBrowserViewControllerBuilder.h"

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
            NSURL *fullUrl = [NSURL URLWithString:fullUrlString];
            BOOL canOpenInVLC = [[UIApplication sharedApplication] canOpenURL:fullUrl];

            if (canOpenInVLC) {
                [[UIApplication sharedApplication] openURL:fullUrl];
            }
            else {
                [self problemAboutVlcToPrompt];
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

        [_viewController.navigationController presentViewController:galleryBrowser
                                                           animated:YES
                                                         completion:nil];
    }
}

/// NO VLC error prompt
- (void)problemAboutVlcToPrompt
{
    NSString *installVLCPrompt = NSLocalizedString(@"Для просмотра установите VLC", @"Prompt in navigation bar of a thread View Controller - shows after user tap on the video and if user do not have VLC on the device");
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
