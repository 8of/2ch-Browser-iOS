//
//  DVBNetworking.m
//  dvach-browser
//
//  Created by Andy on 10/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//
#import <AFNetworking/AFNetworking.h>

#import "DVBNetworking.h"
#import "DVBConstants.h"
#import "DVBBoard.h"
#import "DVBValidation.h"
#import "DVBStatus.h"
#import "Reachlibility.h"

#import "UIImage+DVBImageExtention.h"

static NSString *const REAL_ADDRESS_FOR_BOARDS_LIST = @"https://2ch.hk/makaba/mobile.fcgi?task=get_boards";
static NSString *const URL_TO_GET_USERCODE = @"https://2ch.hk/makaba/makaba.fcgi";

@interface DVBNetworking ()

@property (nonatomic, strong) Reachability *networkReachability;
/**
 *  Captcha stuff
 */
@property (nonatomic, strong) NSString *captchaKey;

@end

@implementation DVBNetworking

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _networkReachability = [Reachability reachabilityForInternetConnection];
    }
    
    return self;
}

/// Check network status.
- (BOOL)getNetworkStatus {

    NetworkStatus networkStatus = [_networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable)
    {
        NSLog(@"Cannot find internet.");
        return NO;
    }
    
    return YES;
}

#pragma mark - Boards list

- (void)getBoardsFromNetworkWithCompletion:(void (^)(NSDictionary *))completion
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects: @"text/html", @"application/json",nil]];
    [manager GET:REAL_ADDRESS_FOR_BOARDS_LIST parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
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

- (void)getThreadsWithBoard:(NSString *)board andPage:(NSUInteger)page andCompletion:(void (^)(NSDictionary *))completion
{
    if ([self getNetworkStatus]) {
        NSString *pageStringValue;
        
        if (page == 0) {
            pageStringValue = @"index";
        }
        else {
            pageStringValue = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)page];
        }
        
        NSString *requestAddress = [[NSString alloc] initWithFormat:@"%@%@/%@.json", DVACH_BASE_URL, board, pageStringValue];
        
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
}

#pragma mark - Single thread

- (void)getPostsWithBoard:(NSString *)board andThread:(NSString *)threadNum andCompletion:(void (^)(NSDictionary *))completion
{
    if ([self getNetworkStatus]) {
        // building URL for getting JSON-thread-answer from mutiple strings
        
        NSString *requestAddress = [[NSString alloc] initWithFormat:@"%@%@/res/%@.json", DVACH_BASE_URL, board, threadNum];
        
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
}

#pragma mark - Passcode

- (void)getUserCodeWithPasscode:(NSString *)passcode andCompletion:(void (^)(NSString *))completion
{
    if ([self getNetworkStatus]) {
        NSString *requestAddress = URL_TO_GET_USERCODE;
        
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
}
/**
 *  Return usercode from cookie or nil if there is no usercode in cookies
 */
- (NSString *)getUsercodeFromCookies
{
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

- (void)postMessageWithTask:(NSString *)task andBoard:(NSString *)board andThreadnum:(NSString *)threadNum andName:(NSString *)name andEmail:(NSString *)email andSubject:(NSString *)subject andComment:(NSString *)comment andcaptchaValue:(NSString *)captchaValue andUsercode:(NSString *)usercode andImagesToUpload:(NSArray *)imagesToUpload andCompletion:(void (^)(DVBMessagePostServerAnswer *))completion
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSString *json = @"1";
    
    NSString *address = [[NSString alloc] initWithFormat:@"%@%@", DVACH_BASE_URL, @"makaba/posting.fcgi"];
    
    NSDictionary *params = @{
                             @"task":task,
                             @"json":json,
                             @"board":board,
                             @"thread":threadNum
                             };
    
    /**
     *  Convert to mutable to add more parameters, depending on situation
     */
    NSMutableDictionary *mutableParams = [params mutableCopy];
    
    /**
     *  Check userCode
     */
    BOOL isUsercodeNotEmpty = ![usercode isEqualToString:@""];
    if (isUsercodeNotEmpty)
    {
        /**
         *  If usercode presented then use as part of the message
         */
        NSLog(@"usercode way: %@", usercode);
        [mutableParams setValue:usercode forKey:@"usercode"];
    }
    else
    {
        /**
         *  Otherwise include captcha values
         */
        /**
         *  Captcha key is fetched in requestCaptchaKeyWithCompletion and written in _captchaKey
         */
        [mutableParams setValue:_captchaKey
                         forKey:@"captcha"];
        [mutableParams setValue:captchaValue
                         forKey:@"captcha_value"];
    }
    
    /**
     *  Back to unmutable dictionary to be safe
     */
    params = mutableParams;
    
    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects: @"application/json",nil]];
    
    [manager POST:address parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData)
     {
         
         /**
          *  Added comment field this way because makaba don't handle it right otherwise
          *  and name
          *  and subject
          *  and e-mail
          */
         [formData appendPartWithFormData:[comment dataUsingEncoding:NSUTF8StringEncoding]
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
                 }
                 else {
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
             /**
              *  If answer is good - make preparations in current ViewController
              */
             NSString *successTitle = NSLocalizedString(@"Успешно", @"Title of the createPostVC when post was successfull");
             
             DVBMessagePostServerAnswer *messagePostServerAnswer = [[DVBMessagePostServerAnswer alloc] initWithSuccess:YES
                                                                                                      andStatusMessage:successTitle
                                                                                                 andThreadToRedirectTo:nil];
             
             if (isRedirectAnswer) {
                 NSString *threadNumToRedirect = [responseDictionary[@"Target"] stringValue];

                 if (threadNumToRedirect) {
                     messagePostServerAnswer = [[DVBMessagePostServerAnswer alloc] initWithSuccess:YES
                                                                                  andStatusMessage:successTitle
                                                                             andThreadToRedirectTo:threadNumToRedirect];
                 }
                 
             }
             completion(messagePostServerAnswer);
         }
         else {

             // If post wasn't successful. Change prompt to error reason.
             DVBMessagePostServerAnswer *messagePostServerAnswer = [[DVBMessagePostServerAnswer alloc] initWithSuccess:NO
                                                                                                      andStatusMessage:reason
                                                                                                 andThreadToRedirectTo:nil];
             completion(messagePostServerAnswer);
         }
         
     }
          failure:^(NSURLSessionDataTask *task, NSError *error)
     {
         NSLog(@"Error: %@", error);
         
         NSString *cancelTitle = NSLocalizedString(@"Ошибка", @"Title of the createPostVC when post was NOT successful");
         DVBMessagePostServerAnswer *messagePostServerAnswer = [[DVBMessagePostServerAnswer alloc] initWithSuccess:NO
                                                                                                  andStatusMessage:cancelTitle
                                                                                             andThreadToRedirectTo:nil];
         completion(messagePostServerAnswer);
     }];
}

#pragma mark - Captcha

- (void)requestCaptchaKeyWithCompletion:(void (^)(NSString *))completion
{
    if ([self getNetworkStatus]) {
        AFHTTPSessionManager *captchaManager = [AFHTTPSessionManager manager];
        captchaManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [captchaManager.responseSerializer setAcceptableContentTypes:[NSSet setWithObject:@"text/plain"]];
        
        [captchaManager GET:GET_CAPTCHA_KEY_URL
                 parameters:nil
                    success:^(NSURLSessionDataTask *task, id responseObject)
         {
             NSString *captchaKeyAnswer = [[NSString alloc] initWithData:responseObject
                                                                encoding:NSUTF8StringEncoding];
             if ([captchaKeyAnswer hasPrefix:@"CHECK"]) {
                 NSArray *arrayOfCaptchaKeyAnswers = [captchaKeyAnswer componentsSeparatedByString: @"\n"];
                 
                 NSString *captchaKey = [arrayOfCaptchaKeyAnswers lastObject];
                 
                 // Set var for requesting Yandex key image now and posting later.
                 _captchaKey = captchaKey;
                 
                 NSString *urlOfYandexCaptchaImage = [[NSString alloc] initWithFormat:GET_CAPTCHA_IMAGE_URL, captchaKey];
                 
                 completion(urlOfYandexCaptchaImage);             
             }
         }
                    failure:^(NSURLSessionDataTask *task, NSError *error)
         {
             NSLog(@"Error: %@", error);
         }];
    }
}

#pragma mark - Thread reporting

- (void)reportThreadWithBoardCode:(NSString *)board andThread:(NSString *)thread andComment:(NSString *)comment
{
    if ([self getNetworkStatus]) {
        AFHTTPSessionManager *reportManager = [AFHTTPSessionManager manager];
        reportManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [reportManager.responseSerializer setAcceptableContentTypes:[NSSet setWithObject:@"text/html"]];

        [reportManager POST:REPORT_THREAD_URL
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
}

@end
