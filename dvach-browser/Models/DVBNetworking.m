//
//  DVBNetworking.m
//  dvach-browser
//
//  Created by Andy on 10/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>

#import "DVBUrls.h"
#import "DVBNetworking.h"
#import "DVBBoard.h"
#import "DVBValidation.h"

#import "UIImage+DVBImageExtention.h"

@implementation DVBNetworking

#pragma mark - Boards list

- (void)getBoardsFromNetworkWithCompletion:(void (^)(NSDictionary *))completion {
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects: @"text/html", @"application/json",nil]];
  [manager GET:[DVBUrls boardsList] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
   {
     completion(responseObject);
   }
       failure:^(AFHTTPRequestOperation *operation, NSError *error)
   {
     NSLog(@"error: %@", error);
     completion(nil);
   }];
}

#pragma mark - Single Board

- (void)getThreadsWithBoard:(NSString *)board andPage:(NSUInteger)page andCompletion:(void (^)(NSDictionary *, NSError *))completion {
  NSString *pageStringValue;

  if (page == 0) {
    pageStringValue = @"index";
  } else {
    pageStringValue = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)page];
  }
  NSString *requestAddress = [[NSString alloc] initWithFormat:@"%@/%@/%@.json", [DVBUrls base], board, pageStringValue];
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects: @"application/json", nil]];

  weakify(self);
  [manager GET:requestAddress parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
   {
     completion(responseObject, nil);
   }
       failure:^(AFHTTPRequestOperation *operation, NSError *error)
   {
     strongify(self);
     if (!self) { return; }
     NSError *finalError = [self updateErrorWithOperation:operation
                                                 andError:error];
     NSLog(@"error while threads: %@", finalError);
     completion(nil, finalError);
   }];
}

#pragma mark - Single thread

- (void)getPostsWithBoard:(NSString *)board andThread:(NSString *)threadNum andPostNum:(NSString *)postNum andCompletion:(void (^)(id))completion {
  // building URL for getting JSON-thread-answer from multiple strings
  NSString *requestAddress = [[NSString alloc] initWithFormat:@"%@/%@/res/%@.json", [DVBUrls base], board, threadNum];
  if (postNum) {
    requestAddress = [[NSString alloc] initWithFormat:@"%@/makaba/mobile.fcgi?task=get_thread&board=%@&thread=%@&num=%@", [DVBUrls base], board, threadNum, postNum];
  }

  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects: @"application/json",nil]];

  [manager GET:requestAddress parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
   {
     completion(responseObject);
   }
       failure:^(AFHTTPRequestOperation *operation, NSError *error)
   {
     NSLog(@"error: %@", error);
     completion(nil);
   }];
}

#pragma mark - Thread reporting

- (void)reportThreadWithBoardCode:(NSString *)board andThread:(NSString *)thread andComment:(NSString *)comment {
  AFHTTPSessionManager *reportManager = [AFHTTPSessionManager manager];
  reportManager.responseSerializer = [AFHTTPResponseSerializer serializer];
  [reportManager.responseSerializer setAcceptableContentTypes:[NSSet setWithObject:@"text/html"]];

  [reportManager POST:[DVBUrls reportThread]
           parameters:nil
              success:^(NSURLSessionDataTask *task, id responseObject)
   {
     NSLog(@"Report sent");
   }
              failure:^(NSURLSessionDataTask *task, NSError *error)
   {
     NSLog(@"Error: %@", error);
   }];
}

#pragma mark - single post

- (void)getPostWithBoardCode:(NSString *)board andThread:(NSString *)thread andPostNum:(NSString *)postNum andCompletion:(void (^)(NSArray *))completion {
  NSString *address = [[NSString alloc] initWithFormat:@"%@/%@", [DVBUrls base], @"makaba/mobile.fcgi"];

  NSDictionary *params =
  @{
    @"task" : @"get_thread",
    @"board" : board,
    @"thread" : thread,
    @"num" : postNum
    };

  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects: @"text/html", @"application/json",nil]];

  [manager GET:address
    parameters:params
       success:^(AFHTTPRequestOperation *operation, id responseObject)
   {
     completion(responseObject);
   }
       failure:^(AFHTTPRequestOperation *operation, NSError *error)
   {
     NSLog(@"error while getting new post in thread: %@", error. localizedDescription);
     completion(nil);
   }];
}

- (NSString * _Nullable)userAgent {
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  NSString *userAgent = [manager.requestSerializer  valueForHTTPHeaderField:NETWORK_HEADER_USERAGENT_KEY];

  return userAgent;
}

#pragma mark - Error handling

- (NSError *)updateErrorWithOperation:(AFHTTPRequestOperation *)operation andError:(NSError *)error {
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)operation.response;
  if ([httpResponse respondsToSelector:@selector(allHeaderFields)]) {
    NSDictionary *dictionary = [httpResponse allHeaderFields];

    BOOL isServerHeaderCloudflareOne = [dictionary[@"Server"] rangeOfString:@"cloudflare"].location != NSNotFound;

    // Two checks:
    // Have refresh header and it's empty
    // Or have cloudflare ref in Server header
    if ((dictionary[ERROR_OPERATION_HEADER_KEY_REFRESH] &&
         ![dictionary[ERROR_OPERATION_HEADER_KEY_REFRESH] isEqualToString:@""]) ||
        isServerHeaderCloudflareOne)
    {
      NSString *refreshUrl = dictionary[ERROR_OPERATION_HEADER_KEY_REFRESH];
      NSRange range = [refreshUrl rangeOfString:ERROR_OPERATION_REFRESH_VALUE_SEPARATOR];
      if (range.location != NSNotFound) {
        NSString *secondpartOfUrl = [refreshUrl substringFromIndex:NSMaxRange(range)];
        NSString *fullUrlToReturn = [NSString stringWithFormat:@"%@/%@", [DVBUrls base], secondpartOfUrl];

        NSDictionary *userInfo = error.userInfo;

        NSMutableDictionary *newErrorDictionary = [@
                                                   {
                                                     ERROR_USERINFO_KEY_IS_DDOS_PROTECTION : @YES,
                                                     ERROR_USERINFO_KEY_URL_TO_CHECK_IN_BROWSER : fullUrlToReturn
                                                   } mutableCopy];

        [newErrorDictionary addEntriesFromDictionary:userInfo];
        userInfo = [newErrorDictionary copy];



        NSError *errorToReturn = [[NSError alloc] initWithDomain:ERROR_DOMAIN_APP
                                                            code:ERROR_CODE_DDOS_CHECK
                                                        userInfo:userInfo];

        return errorToReturn;
      }
    }
  }

  return nil;
}

@end
