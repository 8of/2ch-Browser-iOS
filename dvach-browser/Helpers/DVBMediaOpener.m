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
#import "DVBRouter.h"

@interface DVBMediaOpener ()

@property (nonatomic, weak) UIViewController *viewController;

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
  if ([fullUrlString isEqualToString:@""]) {
    // Empty link case
    return;
  }
  // if contains .webm
  if ([fullUrlString containsString:@".webm"]) {
    NSURL *url = [NSURL URLWithString:fullUrlString];
    [self openInternalWebmWithURL:url];
//    NSURL *fullUrl = [NSURL URLWithString:[fullUrlString stringByReplacingOccurrencesOfString:@"https" withString:@"vlc"]];
//    [self openVLCWithURL:fullUrl];
  }
  // if not
  else {
    [self createAndPushGalleryWithUrlString:fullUrlString
                        andThumbImagesArray:thumbImagesArray
                         andFullImagesArray:fullImagesArray];
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

        _viewController.navigationController.definesPresentationContext = YES;
        [galleryBrowser setModalPresentationStyle:UIModalPresentationOverCurrentContext];
        [_viewController.navigationController presentViewController:galleryBrowser
                                                           animated:YES
                                                         completion:nil];
    }
}

#pragma mark - Webm

- (void)openInternalWebmWithURL:(NSURL *)url
{
  [DVBRouter openWebmFrom:_viewController url:url];
}

#pragma mark - VLC

- (void)openVLCWithURL:(NSURL *)url
{
  BOOL canOpenInVLC = [[UIApplication sharedApplication] canOpenURL:url];

  if (canOpenInVLC) {
    [[UIApplication sharedApplication] openURL:url];
  }
  else {
    [self problemAboutVlcToPrompt];
  }
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
