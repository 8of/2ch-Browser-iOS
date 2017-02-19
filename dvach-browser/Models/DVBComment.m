//
//  DVBComment.m
//  dvach-browser
//
//  Created by Mega on 28/01/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBComment.h"

@implementation DVBComment

@synthesize comment;

#pragma mark Singleton Methods

+ (id)sharedComment
{
    static DVBComment *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init
{
    if (self = [super init]) {
        if (!self.comment) {
            self.comment = @"";
        }
    }
    return self;
}

- (void)topUpCommentWithPostNum:(NSString *)postNum
{
    NSString *oldCommentText = comment;

    NSString *newStringOfComment;

    if ([oldCommentText isEqualToString:@""]) { // creating from empty comment
        newStringOfComment = [[NSString alloc] initWithFormat:@">>%@\n", postNum];
    }
    else { // if there is some text in comment already
        newStringOfComment = [[NSString alloc] initWithFormat:@"\n>>%@\n", postNum];
    }

    NSString *commentToSingleton = [[NSString alloc] initWithFormat:@"%@%@", oldCommentText, newStringOfComment];

    comment = commentToSingleton;
}

- (void)topUpCommentWithPostNum:(NSString *)postNum andOriginalPostText:(NSAttributedString *)originalPostText andQuoteString:(NSString *)quoteString
{
    [self topUpCommentWithPostNum:postNum];

    NSString *additionalCommentString;
    if (quoteString && (quoteString.length > 0)) {
        additionalCommentString = [NSString stringWithFormat:@"%@", quoteString];
    }
    else {
        additionalCommentString = [NSString stringWithFormat:@"%@", originalPostText.string];
    }

    // delete old quote symbols - so we'll not quote the quotes
    additionalCommentString = [additionalCommentString stringByReplacingOccurrencesOfString:@">" withString:@""];

    // insert quotes symbol after all new line symbols
    additionalCommentString = [additionalCommentString stringByReplacingOccurrencesOfString:@"\n" withString:@"\n>"];

    // delete all new empty lines with quotes
    additionalCommentString = [additionalCommentString stringByReplacingOccurrencesOfString:@"\n>\n" withString:@"\n"];

    // merge old comment text + ">" symbol + new comment with ">" symbols inside
    NSString *commentToSingleton = [[NSString alloc] initWithFormat:@"%@>%@\n", comment, additionalCommentString];

    comment = commentToSingleton;
}

@end
