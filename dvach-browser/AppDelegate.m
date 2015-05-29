//
//  AppDelegate.m
//  dvach-browser
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//
#import <AFNetworking/AFNetworking.h>
#import <SDWebImage/SDWebImageManager.h>

#import "AppDelegate.h"
#import "DVBConstants.h"
#import "DVBNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"

#import "DVBPostPhotoContainerView.h"
#import "DVBMarkupButton.h"

@interface AppDelegate ()

@property (nonatomic, strong) DVBNetworking *networking;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self createDefaultSettings];
    [self appearanceTudeUp];
    [self manageAFNetworking];

    return YES;
}

- (void)createDefaultSettings
{
    [self clearAllCaches];

    NSDictionary* defaults = @{
                               USER_AGREEMENT_ACCEPTED:@NO,
                               SETTING_ENABLE_DARK_THEME:@NO,
                               SETTING_ENABLE_LITTLE_BODY_FONT:@NO,
                               PASSCODE:@"",
                               USERCODE:@"",
                               BOARDS_LIST_VERSION:@0
                               };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

    if (!_networking) {
        _networking = [[DVBNetworking alloc] init];
    }

    NSString *passcode = [[NSUserDefaults standardUserDefaults] objectForKey:PASSCODE];
    NSString *usercode = [[NSUserDefaults standardUserDefaults] objectForKey:USERCODE];

    BOOL isPassCodeNotEmpty = ![passcode isEqualToString:@""];
    BOOL isUserCodeEmpty = [usercode isEqualToString:@""];

    if (isPassCodeNotEmpty && isUserCodeEmpty) {
        [_networking getUserCodeWithPasscode:passcode andCompletion:^(NSString *completion) {

            if (completion) {
                [[NSUserDefaults standardUserDefaults] setObject:completion forKey:USERCODE];

                NSString *usercode = completion;
                [self setUserCodeCookieWithUsercode:usercode];
            }
        }];
    }
    else if (!isUserCodeEmpty) {
        [self setUserCodeCookieWithUsercode:usercode];
    }

    // Turn off SHake to Undo because of tags
    [UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;
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

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.8of.dvach-browser" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"dvach-browser" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
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
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {

    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
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

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end