//
//  DVBCaptchaManager.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 09/02/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVBCaptchaManager : NSObject

- (void)getCaptchaImageUrl:(NSString *)threadNum andCompletion:(void (^)(NSString *, NSString *))completion;

@end
