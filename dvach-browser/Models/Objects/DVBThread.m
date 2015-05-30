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

@interface DVBThread ()

@property (nonatomic, strong) NSArray *lastPosts;
@property (nonatomic, strong) NSNumber *postsCountBeforeCheck;

@end

@implementation DVBThread

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
         @"num" : @"num",
         @"comment" : @"comment",
         @"subject" : @"subject",
         @"postsCountBeforeCheck" : @"posts_count",
         @"lastPosts" : @"posts",
         @"timeSinceFirstPost" : @"timestamp"
     };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self == nil) return nil;

    _postsCount = [[NSNumber alloc] initWithInteger:([_postsCountBeforeCheck integerValue] + [_lastPosts count])];

    _lastPosts = nil;
    _postsCountBeforeCheck = nil;

    return self;
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