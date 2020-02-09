//
//  DVBDefaultsManager.h
//  dvach-browser
//
//  Created by Andy on 30/09/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>

#import "DVBConstants.h"
#import "DVBUrls.h"
#import "DVBNetworking.h"
#import "DVBDatabaseManager.h"
#import "DVBPostPhotoContainerView.h"

@interface DVBDefaultsManager : NSObject

@property (nonatomic, class, readonly) BOOL isDarkMode;

+ (NSDictionary *)initialDefaultsMattersForAppReset;
+ (BOOL)needToResetWithStoredDefaults:(NSDictionary *)defaultsToCompare;
- (void)initApp;

@end
