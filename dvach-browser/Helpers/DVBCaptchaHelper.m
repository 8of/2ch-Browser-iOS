//
//  DVBCaptchaHelper.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 19/11/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBCaptchaHelper.h"

@implementation DVBCaptchaHelper

+ (NSString*)appResponseFrom:(NSString *)appResponseId
{
    NSString *fullString = [NSString stringWithFormat:@"%@|%@", appResponseId, AP_CAPTCHA_PRIVATE_KEY];
    const char *s=[fullString cStringUsingEncoding:NSASCIIStringEncoding];
    NSData *keyData=[NSData dataWithBytes:s length:strlen(s)];

    uint8_t digest[CC_SHA256_DIGEST_LENGTH]={0};
    CC_SHA256(keyData.bytes, keyData.length, digest);
    NSData *out=[NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
    NSString *hash=[out description];
    hash = [hash stringByReplacingOccurrencesOfString:@" " withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@"<" withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@">" withString:@""];
    return hash;
}

@end
