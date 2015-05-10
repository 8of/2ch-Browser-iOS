//
//  DVBMessagePostServerAnswer.h
//  dvach-browser
//
//  Created by Mega on 15/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVBMessagePostServerAnswer : NSObject

@property (nonatomic, assign, readonly) BOOL success;
@property (nonatomic, strong, readonly) NSString *statusMessage;
@property (nonatomic, strong, readonly) NSString *threadToRedirectTo;

- (instancetype)initWithSuccess:(BOOL)success
               andStatusMessage:(NSString *)statusMessage
          andThreadToRedirectTo:(NSString *)threadToRedirectTo;

@end
