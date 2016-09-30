//
//  DVBDefaultsManager.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 30/09/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBDefaultsManager.h"

@implementation DVBDefaultsManager

- (void)createDefaultSettingsWithUserAgent:(NSString *)userAgent
{
    [Fabric with:@[[Crashlytics class]]];

    NSDictionary* defaults = @{
                               USER_AGREEMENT_ACCEPTED : @NO,
                               SETTING_ENABLE_DARK_THEME : @NO,
                               SETTING_ENABLE_LITTLE_BODY_FONT : @NO,
                               SETTING_ENABLE_INTERNAL_WEBM_PLAYER : @YES,
                               SETTING_ENABLE_SMOOTH_SCROLLING : @NO,
                               SETTING_ENABLE_TRAFFIC_SAVINGS : @NO,
                               SETTING_CLEAR_THREADS : @NO,
                               SETTING_BASE_DOMAIN : DVACH_DOMAIN,
                               PASSCODE : @"",
                               USERCODE : @"",
                               DEFAULTS_REVIEW_STATUS : @NO,
                               DEFAULTS_USERAGENT_KEY : userAgent
                               };

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Turn off Shake to Undo because of tags on post screen
    [UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;

    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void)defaultsChanged
{
    [DVBUrls reset];
}

@end
