//
//  DVBDvachWebViewViewController.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 11/10/15.
//  Copyright © 2015 8of. All rights reserved.
//

#import "DVBCommon.h"
#import "DVBConstants.h"

#import "DVBDvachWebViewViewController.h"

@interface DVBDvachWebViewViewController () <UIWebViewDelegate>

@property (nonatomic, strong) NSString *urlToCheck;

// UI

@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *closeButton;

@end

@implementation DVBDvachWebViewViewController

- (instancetype)initWithUrlString:(NSString *)urlString andDvachWebViewViewControllerDelegate:(id<DVBDvachWebViewViewControllerProtocol>)dvachWebViewViewControllerDelegate
{
    self = [super init];

    if (self) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:STORYBOARD_NAME_WEBVIEWS
                                                             bundle:nil];

        self = (DVBDvachWebViewViewController *)[storyboard instantiateViewControllerWithIdentifier:STORYBOARD_ID_WEBVIEW_VIEW_CONTROLLER];
        _urlToCheck = urlString;
        _dvachWebViewViewControllerDelegate = dvachWebViewViewControllerDelegate;
    }

    return self;
}

#pragma mark - Lifecircle

- (void)viewDidLoad
{
    [super viewDidLoad];
    _webView.delegate = self;

    self.title = NSLS(@"TITLE_DDOS_CHECK");

    self.closeButton.title = NSLS(@"BUTTON_CLOSE");
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_urlToCheck]]];
}

#pragma mark - UIWebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Error DDoS checking with error: %@", error.localizedDescription);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    _webView.scrollView.contentOffset = CGPointMake(0, 0);
    // Read body of html page
    NSString *html = [webView stringByEvaluatingJavaScriptFromString: @"document.body.outerHTML"];
    NSString *currentURL = webView.request.URL.absoluteString;
    NSLog(@"-- %@", currentURL);

    // Check if body contains part of Два.ч word
    if ([html rangeOfString:WEBVIEW_PART_OF_THE_PAGE_TO_CHECK_MAIN_PAGE].location != NSNotFound) {
        [self closeController];
    }
}

#pragma mark - Actions

/// Dismiss controller and restart board
- (void)closeController
{
    __weak typeof(self) weakSelf = self;

    [self dismissViewControllerAnimated:YES completion:^{
        if (weakSelf.dvachWebViewViewControllerDelegate &&
            [weakSelf.dvachWebViewViewControllerDelegate respondsToSelector:@selector(reloadAfterWebViewDismissing)])
        {
            [weakSelf.dvachWebViewViewControllerDelegate reloadAfterWebViewDismissing];
        }
    }];
}

- (IBAction)closeAction:(id)sender
{
    [self closeController];
}

@end
