//
//  DVBPost.m
//  dvach-browser
//
//  Created by Andy on 13/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBCommon.h"
#import "DVBConstants.h"
#import "DVBPost.h"

@implementation DVBPost

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"num" : @"num",
             @"subject" : @"subject",
             @"timestamp" : @"timestamp",
             @"name" : @"name"
             };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    if (!self) { return nil; }
    _replies = [@[] mutableCopy];
    return self;
}

+ (NSValueTransformer *)numJSONTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSNumber *num, BOOL *success, NSError *__autoreleasing *error) {
        NSString *numToReturn = [[NSString alloc] initWithFormat:@"%ld", (long)num.integerValue ];
        return numToReturn;
    }];
}

+ (NSValueTransformer *)subjectJSONTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *string, BOOL *success, NSError *__autoreleasing *error) {
        NSString *subject;
        if ([string rangeOfString:@"ررً"].location == NSNotFound) {
            subject = string;
        } else {
            NSString *brokenStringHere = NSLS(@"POST_BAD_SYMBOLS_IN_POST");
            subject = brokenStringHere;
        }
        return subject;
    }];
}

@end
