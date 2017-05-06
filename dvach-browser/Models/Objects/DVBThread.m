//
//  DVBThread.m
//  dvach-browser
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "NSString+HTML.h"

#import "DVBConstants.h"
#import "DVBThread.h"
#import "DateFormatter.h"

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

+ (NSValueTransformer *)subjectJSONTransformer
{
  return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *string, BOOL *success, NSError *__autoreleasing *error) {
    return [string stringByConvertingHTMLToPlainText];
  }];
}

+ (NSValueTransformer *)commentJSONTransformer
{
  return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *string, BOOL *success, NSError *__autoreleasing *error) {
    NSString *comment = string;
    comment = [comment stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    return [comment stringByConvertingHTMLToPlainText];
  }];
}

+ (NSValueTransformer *)timeSinceFirstPostJSONTransformer
{
  return [MTLValueTransformer transformerUsingForwardBlock:^id(NSNumber *timestamp, BOOL *success, NSError *__autoreleasing *error) {
    return [DateFormatter dateFromTimestamp:timestamp.integerValue];
  }];
}

+ (NSString *)threadControllerTitleFromTitle:(NSString *)title andNum:(nullable NSString *)num andComment:(nullable NSString *)comment
{
  if (!title || [title isEqualToString:@""]) {
    return num;
  }
  if (!comment || [comment containsString:num]) {
    return num;
  }
  return title;
}

+ (BOOL)isTitle:(NSString *)title madeFromComment:(NSString *)comment
{
  if (title.length > 2 && comment.length > 2) {
    if ([[title substringToIndex:2] isEqualToString:[comment substringToIndex:2]]) {
        return YES;
    }
  }
  return NO;
}

@end
