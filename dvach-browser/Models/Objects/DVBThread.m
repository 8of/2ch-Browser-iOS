//
//  DVBThread.m
//  dvach-browser
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "NSString+HTML.h"
#import "DateFormatter.h"

#import "DVBThread.h"

@implementation DVBThread

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
         @"num" : @"num",
         @"comment" : @"comment",
         @"subject" : @"subject",
         @"postsCount" : @"posts_count",
         @"timeSinceFirstPost" : @"timestamp"
     };
}

+ (NSValueTransformer *)commentJSONTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *string, BOOL *success, NSError *__autoreleasing *error) {

        NSString *comment = string;
        comment = [comment stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
        comment = [comment stringByConvertingHTMLToPlainText];

        return comment;
    }];
}

+ (NSValueTransformer *)timeSinceFirstPostJSONTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSNumber *timestamp, BOOL *success, NSError *__autoreleasing *error) {

        NSString *dateAgo = [DateFormatter dateFromTimestamp:timestamp.integerValue];

        return dateAgo;
    }];
}

@end
