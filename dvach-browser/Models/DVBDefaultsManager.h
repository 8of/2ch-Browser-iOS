//
//  DVBDefaultsManager.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 30/09/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "DVBConstants.h"
#import "DVBUrls.h"

@interface DVBDefaultsManager : NSObject

- (void)createDefaultSettingsWithUserAgent:(NSString *)userAgent;

@end
