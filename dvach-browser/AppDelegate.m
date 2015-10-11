//
//  AppDelegate.m
//  dvach-browser
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <SDWebImage/SDWebImageManager.h>

#import "AppDelegate.h"
#import "DVBConstants.h"
#import "DVBNetworking.h"
#import "DVBDatabaseManager.h"

#import "DVBPostPhotoContainerView.h"
#import "DVBMarkupButton.h"

@interface AppDelegate ()

@property (nonatomic, strong) DVBNetworking *networking;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self createDefaultSettings];
    [self managePasscode];
    [self manageReviewStatus];
    [self appearanceTudeUp];
    [self manageAFNetworking];
    [self manageDb];

    return YES;
}

- (void)createDefaultSettings
{
    [self clearAllCaches];

    if (!_networking) {
        _networking = [[DVBNetworking alloc] init];
    }

    NSString *userAgent = [_networking userAgent];

    NSDictionary* defaults = @{
       USER_AGREEMENT_ACCEPTED : @NO,
       SETTING_ENABLE_DARK_THEME : @NO,
       SETTING_ENABLE_LITTLE_BODY_FONT : @NO,
       SETTING_ENABLE_TRAFFIC_SAVINGS : @NO,
       SETTING_CLEAR_THREADS : @NO,
       PASSCODE : @"",
       USERCODE : @"",
       DEFAULTS_REVIEW_STATUS : @YES,
       DEFAULTS_USERAGENT_KEY : userAgent
    };

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

    // Turn off Shake to Undo because of tags on post screen
    [UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;

    [[SDWebImageManager sharedManager].imageDownloader setValue:userAgent forHTTPHeaderField:NETWORK_HEADER_USERAGENT_KEY];
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

- (void)manageReviewStatus
{
    [_networking getReviewStatus:^(BOOL status) {
        [[NSUserDefaults standardUserDefaults] setBool:status
                                                forKey:DEFAULTS_REVIEW_STATUS];
    }];
}

- (void)clearAllCaches
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[SDImageCache sharedImageCache] clearDisk];
}

/// Create cookies for later posting with super csecret usercode
- (void)setUserCodeCookieWithUsercode:(NSString *)usercode
{
    NSDictionary *usercodeCookieDictionary = @{
        @"name":@"usercode_nocaptcha",
        @"value":usercode
    };
    NSHTTPCookie *usercodeCookie = [[NSHTTPCookie alloc] initWithProperties:usercodeCookieDictionary];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:usercodeCookie];
}

- (void)deleteUsercodeOldData
{
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:USERCODE];
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        if ([cookie.name isEqualToString:@"usercode_nocaptcha"]) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
            break;
        }
    }
}

/// Execute all AFNetworking methods that need to be executed one time for entire app.
- (void)manageAFNetworking
{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
}

/// Tuning appearance for entire app.
- (void)appearanceTudeUp
{
    [UIView appearance].tintColor = DVACH_COLOR;

    _enableDarkTheme = [[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME];

    [UIActivityIndicatorView appearance].color = DVACH_COLOR;

    [UIButton appearanceWhenContainedIn:[DVBPostPhotoContainerView class], nil].tintColor = [UIColor whiteColor];

    if (_enableDarkTheme) {
        UIView *colorView = [[UIView alloc] init];
        colorView.backgroundColor = CELL_SEPARATOR_COLOR;
        [UITableViewCell appearance].selectedBackgroundView = colorView;
    }
}

- (void)manageDb
{
    BOOL shouldClearDB = [[NSUserDefaults standardUserDefaults] boolForKey:SETTING_CLEAR_THREADS];

    if (shouldClearDB) {
        DVBDatabaseManager *dbManager = [DVBDatabaseManager sharedDatabase];
        [dbManager clearAll];
    }
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"dvach-browser" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"dvach-browser.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];

    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
