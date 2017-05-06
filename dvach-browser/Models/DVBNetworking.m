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

static NSString * const NO_CAPTCHA_ANSWER_CODE = @"disabled";

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

#pragma mark - Passcode

- (void)getUserCodeWithPasscode:(NSString *)passcode andCompletion:(void (^)(NSString *))completion {
  NSString *requestAddress = [DVBUrls getUsercode];

  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects: @"text/html",nil]];

  NSDictionary *params = @{
                           @"task":@"auth",
                           @"usercode":passcode
                           };

  [manager POST:requestAddress parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
   {
     NSString *usercode = [self getUsercodeFromCookies];
     completion(usercode);
   }
        failure:^(AFHTTPRequestOperation *operation, NSError *error)
   {
     // NSLog(@"error: %@", error);
     // error here is OK we just need to extract usercode from cookies
     NSString *usercode = [self getUsercodeFromCookies];
     completion(usercode);
   }];
}

/// Return usercode from cookie or nil if there is no usercode in cookies
- (NSString *)getUsercodeFromCookies {
  NSArray *cookiesArray = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
  for (NSHTTPCookie *cookie in cookiesArray) {
    BOOL isThisUsercodeCookie = [cookie.name isEqualToString:@"usercode_nocaptcha"];
    if (isThisUsercodeCookie) {
      NSString *usercode = cookie.value;
      NSLog(@"usercode success");
      return usercode;
    }
  }
  return nil;
}

#pragma mark - Posting

- (void)postMessageWithBoard:(NSString *)board andThreadnum:(NSString *)threadNum andName:(NSString *)name andEmail:(NSString *)email andSubject:(NSString *)subject andComment:(NSString *)comment andUsercode:(NSString *)usercode andImagesToUpload:(NSArray *)imagesToUpload andCaptchaParameters:(NSDictionary *)captchaParameters andCompletion:(void (^)(DVBMessagePostServerAnswer *))completion {
  // Prevent crashing
  if (!board || !threadNum) {
    return;
  }

  AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
  manager.responseSerializer = [AFHTTPResponseSerializer serializer];

  NSString *address = [[NSString alloc] initWithFormat:@"%@/%@", [DVBUrls base], @"makaba/posting.fcgi"];

  NSDictionary *params =
  @{
    @"task" : @"post",
    @"json" : @"1",
    @"board" : board,
    @"thread" : threadNum
    };

  // Convert to mutable to add more parameters, depending on situation
  NSMutableDictionary *mutableParams = [params mutableCopy];

  // if new captcha
  if (captchaParameters) {
    [mutableParams addEntriesFromDictionary:captchaParameters];
  } else {
    // Check userCode
    BOOL isUsercodeNotEmpty = ![usercode isEqualToString:@""];
    if (isUsercodeNotEmpty) {
      // If usercode presented then use as part of the message
      // NSLog(@"usercode way: %@", usercode);
      mutableParams[@"usercode"] = usercode;
    }
  }

  // Back to unmutable dictionary to be safe
  params = [mutableParams copy];

  [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects: @"application/json",nil]];

  [manager POST:address parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData)
   {
     /**
      *  Added comment field this way because makaba don't handle it right otherwise
      *  and name
      *  and subject
      *  and e-mail
      */
     NSString *commentToSend = comment;
     if ([comment isEqualToString:NSLS(@"PLACEHOLDER_COMMENT_FIELD")]) {
       commentToSend = @"";
     }
     [formData appendPartWithFormData:[commentToSend dataUsingEncoding:NSUTF8StringEncoding]
                                 name:@"comment"];
     [formData appendPartWithFormData:[name dataUsingEncoding:NSUTF8StringEncoding]
                                 name:@"name"];
     [formData appendPartWithFormData:[subject dataUsingEncoding:NSUTF8StringEncoding]
                                 name:@"subject"];
     [formData appendPartWithFormData:[email dataUsingEncoding:NSUTF8StringEncoding]
                                 name:@"email"];

     // Check if we have images to upload
     if (imagesToUpload) {
       NSUInteger imageIndex = 1;
       for (UIImage *imageToLoad in imagesToUpload) {
         NSData *fileData;
         NSString *imageName = [NSString stringWithFormat:@"image%ld", (unsigned long)imageIndex];
         NSString *imageFilename = [NSString stringWithFormat:@"image.%@", imageToLoad.imageExtention];
         NSString *imageMimeType;
         BOOL isThisJpegImage = [imageToLoad.imageExtention isEqualToString:@"jpg"];

         // Mime type for jpeg differs from its file extention string
         if (isThisJpegImage) {
           imageMimeType = @"image/jpeg";
           fileData = UIImageJPEGRepresentation(imageToLoad, 1.0);
         } else {
           imageMimeType = [NSString stringWithFormat:@"image/%@", imageToLoad.imageExtention];
           fileData = UIImagePNGRepresentation(imageToLoad);
         }
         [formData appendPartWithFileData:fileData
                                     name:imageName
                                 fileName:imageFilename
                                 mimeType:imageMimeType];
         imageIndex++;
       }
     }
   }
        success:^(NSURLSessionDataTask *task, id responseObject)
   {
     NSString *responseString = [[NSString alloc] initWithData:responseObject
                                                      encoding:NSUTF8StringEncoding];
     NSLog(@"Success: %@", responseString);

     NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
     NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData
                                                                        options:0
                                                                          error:nil];
     /**
      *  Status field from response.
      */
     NSString *status = responseDictionary[@"Status"];
     /**
      *  Reason field from response.
      */
     NSString *reason = responseDictionary[@"Reason"];

     /**
      *  Compare answer to predefined values;
      */
     BOOL isOKanswer = [status isEqualToString:@"OK"];
     BOOL isRedirectAnswer = [status isEqualToString:@"Redirect"];

     if (isOKanswer || isRedirectAnswer) {
       // If answer is good - make preparations in current ViewController
       NSString *successTitle = NSLS(@"POST_STATUS_SUCCESS");

       NSString *postNum = [responseDictionary[@"Num"] stringValue];

       DVBMessagePostServerAnswer *messagePostServerAnswer = [[DVBMessagePostServerAnswer alloc] initWithSuccess:YES
                                                                                                andStatusMessage:successTitle
                                                                                                          andNum:postNum
                                                                                           andThreadToRedirectTo:nil];

       if (isRedirectAnswer) {
         NSString *threadNumToRedirect = [responseDictionary[@"Target"] stringValue];

         if (threadNumToRedirect) {
           messagePostServerAnswer = [[DVBMessagePostServerAnswer alloc] initWithSuccess:YES
                                                                        andStatusMessage:successTitle
                                                                                  andNum:nil
                                                                   andThreadToRedirectTo:threadNumToRedirect];
         }

       }
       completion(messagePostServerAnswer);
     }
     else {

       // If post wasn't successful. Change prompt to error reason.
       DVBMessagePostServerAnswer *messagePostServerAnswer = [[DVBMessagePostServerAnswer alloc] initWithSuccess:NO
                                                                                                andStatusMessage:reason
                                                                                                          andNum:nil
                                                                                           andThreadToRedirectTo:nil];
       completion(messagePostServerAnswer);
     }

   }
        failure:^(NSURLSessionDataTask *task, NSError *error)
   {
     NSLog(@"Error: %@", error);

     NSString *cancelTitle = NSLS(@"ERROR");
     DVBMessagePostServerAnswer *messagePostServerAnswer = [[DVBMessagePostServerAnswer alloc] initWithSuccess:NO
                                                                                              andStatusMessage:cancelTitle
                                                                                                        andNum:nil
                                                                                         andThreadToRedirectTo:nil];
     completion(messagePostServerAnswer);
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

- (void)canPostWithoutCaptcha:(void (^)(BOOL))completion {
  NSString *address = [[NSString alloc] initWithFormat:@"%@/%@", [DVBUrls base], @"makaba/captcha.fcgi?type=2chaptcha&action=thread"];
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects: @"text/plain", nil]];

  [manager GET:address
    parameters:nil
       success:^(AFHTTPRequestOperation *operation, id responseObject)
   {
     completion(NO);
   }
       failure:^(AFHTTPRequestOperation *operation, NSError *error)
   {
     NSString *reponseString = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
     if ([reponseString.lowercaseString rangeOfString:NO_CAPTCHA_ANSWER_CODE].location == NSNotFound ) {
       completion(NO);
     } else {
       completion(YES);
     }
   }];
}

- (void)getCaptchaImageUrl:(NSString * _Nullable)threadNum andCompletion:(void (^)(NSString * _Nullable, NSString * _Nullable))completion {
  NSString *address = [[NSString alloc] initWithFormat:@"%@/%@", [DVBUrls base], @"api/captcha/2chaptcha/id"];
  if (threadNum != nil) {
    address = [NSString stringWithFormat:@"%@?thread=%@", address, threadNum];
  }
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

  [manager GET:address
    parameters:nil
       success:^(AFHTTPRequestOperation *operation, id responseObject)
   {
     if (responseObject[@"id"] != nil) {
       NSString *captchaId = responseObject[@"id"];

       NSString *captchaImageAddress = [[NSString alloc] initWithFormat:@"%@/%@%@", [DVBUrls base], @"api/captcha/2chaptcha/image/", captchaId];
       completion(captchaImageAddress, captchaId);
     } else {
       completion(nil, nil);
     }
   }
       failure:^(AFHTTPRequestOperation *operation, NSError *error)
   {
     completion(nil, nil);
   }];
}

- (NSString * _Nullable)userAgent {
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  NSString *userAgent = [manager.requestSerializer  valueForHTTPHeaderField:NETWORK_HEADER_USERAGENT_KEY];

  return userAgent;
}

- (void)tryApCaptchaWithCompletion:(void (^)(NSString * _Nullable))completion {
  NSString *address = [[NSString alloc] initWithFormat:@"%@/%@%@", [DVBUrls base], @"api/captcha/app/id/", AP_CAPTCHA_PUBLIC_KEY];
  [[AFHTTPRequestOperationManager manager] GET:address
                                    parameters:nil
                                       success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                                         if (responseObject[@"id"] != nil) {
                                           NSString *appResponseId = responseObject[@"id"];
                                           completion(appResponseId);
                                         } else {
                                           completion(nil);
                                         }
                                       }
                                       failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
                                         completion(nil);
                                       }];
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
