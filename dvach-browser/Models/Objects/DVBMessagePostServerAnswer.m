//
//  DVBMessagePostServerAnswer.m
//  dvach-browser
//
//  Created by Mega on 15/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBMessagePostServerAnswer.h"

@implementation DVBMessagePostServerAnswer

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Need additional parameters"
                                   reason:@"Use -[[DVBMessagePostServerAnswer alloc] initWithSuccess:andStatusMessage:andThreadToRedirectTo:]"
                                 userInfo:nil];
    
    return nil;
}

- (instancetype)initWithSuccess:(BOOL)success
               andStatusMessage:(NSString *)statusMessage
          andThreadToRedirectTo:(NSString *)threadToRedirectTo
{
    self = [super init];
    if (self)
    {
        _success = success;
        _statusMessage = statusMessage;
        _threadToRedirectTo = threadToRedirectTo;
    }
    
    return self;
}

@end
