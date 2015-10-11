//
//  DVBUrlRequestHelper.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 11/10/15.
//  Copyright © 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVBUrlRequestHelper : NSObject

+ (NSURLRequest *)urlRequestForUrlString:(NSString *)urlString;

@end
