//
//  DVBCaptchaHelper.h
//  dvach-browser
//
//  Created by Andy on 19/11/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

@interface DVBCaptchaHelper : NSObject

+ (NSString * _Nullable)appResponseFrom:(NSString * _Nonnull)appResponseId;

@end
