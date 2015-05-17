//
//  DateFormatter.h
//  Tabula
//
//  Created by Alexander Tewpin on 02/08/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateFormatter : NSObject

+ (NSString *)dateFromTimestamp:(NSInteger)timestamp;

@end
