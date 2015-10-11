//
//  DVBUrlRequestHelper.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 11/10/15.
//  Copyright © 2015 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBUrlRequestHelper.h"

@implementation DVBUrlRequestHelper

+ (NSURLRequest *)urlRequestForUrlString:(NSString *)urlString
{
    NSURL *thumbnailUrl = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:thumbnailUrl];
    NSString *userAgent = [[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_USERAGENT_KEY];
    [request setValue:userAgent forHTTPHeaderField:NETWORK_HEADER_USERAGENT_KEY];

    return [request copy];
}

@end
