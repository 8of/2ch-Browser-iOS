//
//  DVBNetworking.m
//  dvach-browser
//
//  Created by Andy on 10/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBNetworking.h"
#import <AFNetworking/AFNetworking.h>
#import "DVBConstants.h"
#import "DVBBoardObj.h"
#import "DVBValidation.h"
#import "DVBStatus.h"
#import "Reachability.h"

typedef NS_ENUM(NSUInteger, Status)
{
    Revision = 0,
    Production,
    Semi
};

static NSString *const MY_ADDRESS_FOR_BOARDS_LIST = @"http://8of.org/2ch/boards.json";
static NSString *const REAL_ADDRESS_FOR_BOARDS_LIST = @"https://2ch.hk/makaba/mobile.fcgi?task=get_boards";
static NSString *const URL_TO_GET_USERCODE = @"https://2ch.hk/makaba/makaba.fcgi";

@interface DVBNetworking ()

@property (nonatomic, strong) Reachability *networkReachability;

@end

@implementation DVBNetworking

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _networkReachability = [Reachability reachabilityForInternetConnection];
    }
    
    return self;
}

/**
 *  Check network status.
 */
- (BOOL)getNetworkStatus {

    NetworkStatus networkStatus = [_networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable)
    {
        NSLog(@"Cannot find internet.");
        return NO;
    }
    
    return YES;
}
/**
 *  This one is tricky.
 *  We trying to understand with help of my own server - is it application under review now or not?
 */
- (void)getServiceStatus:(void (^)(NSUInteger))completion
{
    
    if ([self getNetworkStatus])
    {
        [self getServiceStatusLater:^(NSUInteger status)
        {
            completion(status);
        }];
    }
}

#pragma mark - Boards list

- (void)getServiceStatusLater:(void (^)(NSUInteger))completion
{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [manager GET:STATUS_REQUEST_ADDRESS parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSUInteger status = [responseObject[@"status"] integerValue];
        NSUInteger version = [responseObject[@"version"] integerValue];
        DVBStatus *statusModel = [DVBStatus sharedStatus];
        [statusModel setStatus:status andVersion:version];
        completion(status);
    }
         failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"error: %@", error);
        completion(0);
    }];
}

- (void)getBoardsFromNetworkWithCompletion:(void (^)(NSDictionary *))completion
{
    
    [self getServiceStatus:^(NSUInteger status)
    {
        NSLog(@"Server status: %lu", (unsigned long)status);
        
        // DVBStatus *statusModel = [DVBStatus sharedStatus];
        // [statusModel setStatus:status];
        
        NSString *boardListAddress;
        Status statusSwitch = status;
        switch (statusSwitch)
        {
            case Revision:
                _filterContent = YES;
                boardListAddress = MY_ADDRESS_FOR_BOARDS_LIST;
                break;
            case Production:
                /**
                 *  If my server status tell me that application in production already - then we don't need filter content and just show what we've got.
                 */
                _filterContent = NO;
                boardListAddress = REAL_ADDRESS_FOR_BOARDS_LIST;
                break;
            case Semi:
                /**
                 *  for later use
                 *  there will be the 3rd stance for smart showing/hiding
                 */
                _filterContent = NO;
                boardListAddress = MY_ADDRESS_FOR_BOARDS_LIST;
                break;
        }
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects: @"text/html", @"application/json",nil]];
        [manager GET:boardListAddress parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
        {
            completion(responseObject);
        }
             failure:^(AFHTTPRequestOperation *operation, NSError *error)
        {
            NSLog(@"error: %@", error);
            completion(nil);
        }];
    }];
}

#pragma mark - Single Board

- (void)getThreadsWithBoard:(NSString *)board
                    andPage:(NSUInteger)page
              andCompletion:(void (^)(NSDictionary *))completion
{
    if ([self getNetworkStatus])
    {
        NSString *pageStringValue;
        
        if (page == 0)
        {
            pageStringValue = @"index";
        }
        else
        {
            pageStringValue = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)page];
        }
        
        NSString *requestAddress = [[NSString alloc] initWithFormat:@"%@%@/%@.json", DVACH_BASE_URL, board, pageStringValue];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects: @"application/json",nil]];
        
        [manager GET:requestAddress parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
        {
            completion(responseObject);
        }
             failure:^(AFHTTPRequestOperation *operation, NSError *error)
        {
            NSLog(@"error: %@", error);
            completion(nil);
        }];
    }
}

#pragma mark - Passcode

- (void)getUserCodeWithPasscode:(NSString *)passcode
                  andCompletion:(void (^)(NSString *))completion
{
    
    NSString *requestAddress = URL_TO_GET_USERCODE;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects: @"text/html",nil]];
    
    NSDictionary *params = @{
                             @"task":@"auth",
                             @"usercode":passcode
                             };
    
    [manager POST:requestAddress parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSString *usercode = [self getUsercodeFromCookies];
         completion(usercode);
     }
         failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         // NSLog(@"error: %@", error);
         NSString *usercode = [self getUsercodeFromCookies];
         completion(usercode);
     }];
}
/**
 *  Return usercode from cookie or nil if there is no usercode in cookies
 */
- (NSString *)getUsercodeFromCookies {
    NSArray *cookiesArray = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *cookie in cookiesArray) {
        BOOL isThisUsercodeCookie = [cookie.name isEqualToString:@"usercode"];
        if (isThisUsercodeCookie) {
            NSString *usercode = cookie.value;
            NSLog(@"usercode success");
            return usercode;
        }
    }
    return nil;
}

@end