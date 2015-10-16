//
//  DVBCaptchaViewController.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 13/09/15.
//  Copyright © 2015 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBComment.h"

#import "DVBCaptchaViewController.h"

static NSString *const JS_FILE_NAME = @"hideUselessItems";

@interface DVBCaptchaViewController () <UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;

@end

@implementation DVBCaptchaViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _webView.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSString *captchaUrlString = [NSString stringWithFormat:@"https://www.google.com/recaptcha/api/fallback?k=%@", DVACH_RECAPTCHA_KEY];
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:captchaUrlString]]];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSDictionary *headers = [request allHTTPHeaderFields];
    BOOL hasReferer = [headers objectForKey:@"Referer"]!=nil;
    if (hasReferer) {
        // .. is this my referer?
        return YES;
    } else {
        // relaunch with a modified request
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL *url = [request URL];
                NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
                [request setHTTPMethod:@"GET"];
                [request setValue:DVACH_BASE_URL forHTTPHeaderField: @"Referer"];
                [self.webView loadRequest:request];
            });
        });
        return NO;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    _webView.scrollView.contentOffset = CGPointMake(0, 0);
    // Read body of html page
    NSString  *html = [webView stringByEvaluatingJavaScriptFromString: @"document.body.innerHTML"];

    // Add own CSS to turn off useless buttons
    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:JS_FILE_NAME ofType:@"js"];
    NSString *scriptContent = [NSString stringWithContentsOfFile:scriptPath
                                                        encoding:NSUTF8StringEncoding
                                                           error:nil];
    [_webView stringByEvaluatingJavaScriptFromString:scriptContent];

    // Check if body contains element with captcha response
    if ([html rangeOfString:@"fbc-verification-token"].location != NSNotFound) {

        // Cut the key
        NSString *key = [webView stringByEvaluatingJavaScriptFromString: @"document.getElementsByTagName('textarea')[0].innerHTML"];

        // Save key to comment singleton
        DVBComment *sharedComment = [DVBComment sharedComment];
        sharedComment.captchaKey = key;
        [self closeController];
    }
}

#pragma - Actions

/// Dismiss captcha controller and start posting
- (void)closeController
{
    [self.navigationController popViewControllerAnimated:YES];

    if (_captchaViewControllerDelegate &&
        [_captchaViewControllerDelegate respondsToSelector:@selector(captchaBeenChecked)])
    {
        DVBComment *sharedComment = [DVBComment sharedComment];

        if (sharedComment.captchaKey &&
            ![sharedComment.captchaKey isEqualToString:@""])
        {
            [_captchaViewControllerDelegate captchaBeenChecked];
        }
    }
}

@end
