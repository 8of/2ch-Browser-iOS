//
//  DVBDefaultsManager.m
//  dvach-browser
//
//  Created by Andy on 30/09/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <AsyncDisplayKit/ASPINRemoteImageDownloader.h>
#import <PINCache/PINCache.h>
#import <SDWebImage/SDWebImageManager.h>

#import "DVBDefaultsManager.h"

@interface DVBDefaultsManager ()

@property (nonatomic, strong, nonnull) DVBNetworking *networking;

@end

@implementation DVBDefaultsManager

+ (NSDictionary *)initialDefaultsMattersForAppReset
{
    BOOL defDarkTheme = [[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME];
    BOOL defClearThreads = [[NSUserDefaults standardUserDefaults] boolForKey:SETTING_CLEAR_THREADS];
    return @
    {
    SETTING_ENABLE_DARK_THEME: @(defDarkTheme),
    SETTING_CLEAR_THREADS: @(defClearThreads)
    };
}

+ (BOOL)needToResetWithStoredDefaults:(NSDictionary *)defaultsToCompare
{
    BOOL defDarkTheme = [[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME];
    BOOL defClearThreads = [[NSUserDefaults standardUserDefaults] boolForKey:SETTING_CLEAR_THREADS];
    NSNumber *storedDefDarkTheme = defaultsToCompare[SETTING_ENABLE_DARK_THEME];
    NSNumber *storedDefClearThreads = defaultsToCompare[SETTING_CLEAR_THREADS];

    if (storedDefDarkTheme.boolValue != defDarkTheme || storedDefClearThreads.boolValue != defClearThreads) {
        return YES;
    }

    return NO;
}

+ (BOOL)isDarkMode
{
    BOOL darkSetting = [[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME];
    if (@available(iOS 13.0, *)) {
        return [UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark || darkSetting;
    } else {
        return darkSetting;
    }
}

- (void)dealloc
{
    [self observeDefaults:NO];
}

- (void)initApp
{

  _networking = [[DVBNetworking alloc] init];
  NSString *userAgent = [_networking userAgent];

  // User defaults
  NSDictionary* defaults = @{
                             USER_AGREEMENT_ACCEPTED : @NO,
                             SETTING_ENABLE_DARK_THEME : @NO,
                             SETTING_CLEAR_THREADS : @NO,
                             SETTING_FORCE_CAPTCHA : @NO,
                             SETTING_BASE_DOMAIN : DVACH_DOMAIN,
                             PASSCODE : @"",
                             USERCODE : @"",
                             DEFAULTS_AGE_CHECK_STATUS : @NO,
                             DEFAULTS_USERAGENT_KEY : userAgent
                             };

  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];

  // Turn off Shake to Undo because of tags on post screen
  [UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;

  [self manageDownloadsUserAgent:userAgent];
  [self managePasscode];
  [self manageAFNetworking];
  [self manageDb];
  [self appearanceTuneUp];
  [self observeDefaults:YES];
}

- (void)manageDownloadsUserAgent:(NSString *)userAgent
{
  // Prevent Clauda from shitting on my network queries
  [[SDWebImageManager sharedManager].imageDownloader setValue:userAgent
                                           forHTTPHeaderField:NETWORK_HEADER_USERAGENT_KEY];
  [ASPINRemoteImageDownloader setSharedImageManagerWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
  
}

- (void)observeDefaults:(BOOL)enable
{
    if (enable) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(defaultsChanged)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(defaultsChanged)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)managePasscode
{
    NSString *passcode = [[NSUserDefaults standardUserDefaults] objectForKey:PASSCODE];
    NSString *usercode = [[NSUserDefaults standardUserDefaults] objectForKey:USERCODE];

    BOOL isPassCodeNotEmpty = ![passcode isEqualToString:@""];
    BOOL isUserCodeEmpty = [usercode isEqualToString:@""];

    if (isPassCodeNotEmpty && isUserCodeEmpty) {
        [_networking getUserCodeWithPasscode:passcode
                               andCompletion:^(NSString *completion)
         {
             if (completion) {
                 [[NSUserDefaults standardUserDefaults] setObject:completion forKey:USERCODE];
                 [[NSUserDefaults standardUserDefaults] synchronize];

                 NSString *usercode = completion;
                 [self setUserCodeCookieWithUsercode:usercode];
             }
         }];
    } else if (!isPassCodeNotEmpty) {
        [self deleteUsercodeOldData];
    } else if (!isUserCodeEmpty) {
        [self setUserCodeCookieWithUsercode:usercode];
    }
}



/// Execute all AFNetworking methods that need to be executed one time for entire app.
- (void)manageAFNetworking
{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
}

/// Create cookies for later posting with super csecret usercode
- (void)setUserCodeCookieWithUsercode:(NSString *)usercode
{
    NSDictionary *usercodeCookieDictionary = @{
                                               @"name" : @"usercode_nocaptcha",
                                               @"value" : usercode
                                               };
    NSHTTPCookie *usercodeCookie = [[NSHTTPCookie alloc] initWithProperties:usercodeCookieDictionary];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:usercodeCookie];
}

- (void)deleteUsercodeOldData
{
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:USERCODE];
    [[NSUserDefaults standardUserDefaults] synchronize];
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        if ([cookie.name isEqualToString:@"usercode_nocaptcha"]) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
            break;
        }
    }
}

- (void)manageDb
{
    BOOL shouldClearDB = [[NSUserDefaults standardUserDefaults] boolForKey:SETTING_CLEAR_THREADS];

    if (shouldClearDB) {
        [self clearDB];
    }
}

- (void)clearDB
{
    [self clearAllCaches];
    DVBDatabaseManager *dbManager = [DVBDatabaseManager sharedDatabase];
    [dbManager clearAll];

    // Disable observing to prevent dead lock because of notificaitons
    [self observeDefaults:NO];

    // Disable setting
    [[NSUserDefaults standardUserDefaults] setBool:NO
                                            forKey:SETTING_CLEAR_THREADS];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Re-enable Defaults observing
    [self observeDefaults:YES];
}

- (void)clearAllCaches
{
  [[NSURLCache sharedURLCache] removeAllCachedResponses];
  [[SDImageCache sharedImageCache] clearDisk];
  [[PINCache sharedCache] removeAllObjects];
}

/// Tuning appearance for entire app.
- (void)appearanceTuneUp
{
    [UIView appearance].tintColor = DVACH_COLOR;
    [UIButton appearanceWhenContainedIn:[DVBPostPhotoContainerView class], nil].tintColor = [UIColor whiteColor];
    
    UIView *colorView = [[UIView alloc] init];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        colorView.backgroundColor = CELL_SEPARATOR_COLOR_BLACK;
    } else {
        colorView.backgroundColor = CELL_SEPARATOR_COLOR;
    }
    [UITableViewCell appearance].selectedBackgroundView = colorView;
}

- (void)defaultsChanged
{
    [DVBUrls reset];
    [self clearDB];
    [self appearanceTuneUp];
}

@end
