//
//  DVBCaptchaManager.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 09/02/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBCaptchaManager.h"
#import "DVBNetworking.h"

@interface DVBCaptchaManager ()

@property (nonatomic, strong) DVBNetworking *networkManager;

@end

@implementation DVBCaptchaManager

- (instancetype)init
{
    self = [super init];

    if (self) {
        _networkManager = [[DVBNetworking alloc] init];
    }

    return self;
}

- (void)getCaptchaImageUrl:(BOOL)thread andCompletion:(void (^)(NSString *, NSString *))completion
{
    [_networkManager getCaptchaImageUrl:thread
                          andCompletion:^(NSString *responseString)
    {
        if (responseString) {
            NSString *stringTorepalce = [NSString stringWithFormat:@"%@\n", DVACH_CAPTCHA_ANSWER_CHECK_KEYWORD];
            NSRange replaceRange = [responseString rangeOfString:stringTorepalce];
            NSString *idResult = [responseString stringByReplacingCharactersInRange:replaceRange withString:@""];
            [idResult stringByTrimmingCharactersInSet:[NSCharacterSet  whitespaceAndNewlineCharacterSet]];

            NSString *fullUrl = [[NSString alloc] initWithFormat:@"%@%@%@", DVACH_BASE_URL, @"makaba/captcha.fcgi?type=2chaptcha&action=image&id=", idResult];
            completion(fullUrl, idResult);
        } else {
            completion(nil, nil);
        }

    }];
}

@end
