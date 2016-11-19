//
//  DVBCaptchaHelper.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 19/11/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

@interface DVBCaptchaHelper : NSObject

+ (NSString*)appResponseFrom:(NSString *)appResponseId;

@end
