//
//  DVBPost.m
//  dvach-browser
//
//  Created by Andy on 13/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DateFormatter.h"

#import "DVBPost.h"

@interface DVBPost ()

@property (nonatomic, assign) NSInteger timestamp;

@end

@implementation DVBPost

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"num" : @"num",
             @"subject" : @"subject",
             @"timestamp" : @"timestamp",
             @"dateAgo" : @"timestamp",
             @"name" : @"name"
             };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self == nil) return nil;

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
        }
        else {
            NSString *brokenStringHere = NSLocalizedString(@"Пост содержит запрещённые символы", @"Вставка в пост о том, что он содержит сломаные символы");
            subject = brokenStringHere;
        }

        return subject;
    }];
}

+ (NSValueTransformer *)dateAgoJSONTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSNumber *timestamp, BOOL *success, NSError *__autoreleasing *error) {

        NSString *dateAgo = [DateFormatter dateFromTimestamp:timestamp.integerValue];

        return dateAgo;
    }];
}

- (void)updateDateAgo
{
    _dateAgo = [DateFormatter dateFromTimestamp:_timestamp];
}

@end