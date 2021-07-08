//
//  DVBCaptchaManager.m
//  dvach-browser
//
//  Created by Andy on 09/02/16.
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

- (void)getCaptchaImageUrl:(NSString *)threadNum andCompletion:(void (^)(NSString *, NSString *, NSError *))completion
{
    [_networkManager getCaptchaImageUrl:threadNum
                          andCompletion:^( NSString * _Nullable fullUrl, NSString * _Nullable captchaId, NSError * _Nullable error)
    {
        if (fullUrl) {
            completion(fullUrl, captchaId, nil);
        } else {
            completion(nil, nil, error);
        }
    }];
}

@end
