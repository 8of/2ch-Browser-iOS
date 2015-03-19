//
//  AppDelegate.m
//  dvach-browser
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//
#import <AFNetworking/AFNetworking.h>

#import "AppDelegate.h"
#import "DVBConstants.h"
#import "DVBBadPost.h"
#import "DVBBadPostStorage.h"
#import "AFNetworkActivityIndicatorManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self createDefaultSettings];
    [self manageAFNetworking];
    [self appearanceTudeUp];
    return YES;
}

- (void)createDefaultSettings {
    NSDictionary* defaults = @{USER_AGREEMENT_ACCEPTED:@NO, OPEN_EXTERNAL_LINKS_IN_CHROME:@NO, USERCODE:@"", BOARDS_LIST_VERSION:@0};
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    
    /**
     *  Create cookies for later posting
     */
    NSString *usercode = [[NSUserDefaults standardUserDefaults] objectForKey:USERCODE];
    BOOL isUsercodeNotEmpty = ![usercode isEqualToString:@""];
    
    if (isUsercodeNotEmpty)
    {
        NSDictionary *usercodeCookieDictionary = @{@"name":@"usercode",
                                                   @"value":usercode
                                                   };
        NSHTTPCookie *usercodeCookie = [[NSHTTPCookie alloc] initWithProperties:usercodeCookieDictionary];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:usercodeCookie];
    }
}
/**
 *  Execute all AFNetworking methods that need to be executed one time for entire app.
 */
- (void)manageAFNetworking {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
}
/**
 *  Tuning appearance for entire app.
 */
- (void)appearanceTudeUp {
    /**
     *  UILabek for tableviewcell headers
     */
     // [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class],nil] setFont:[UIFont boldSystemFontOfSize:11.0f]];
}

@end