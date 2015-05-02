//
//  DVBPost.m
//  dvach-browser
//
//  Created by Andy on 13/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBPost.h"

@implementation DVBPost

- (instancetype)initWithNum:(NSString *)postNum subject:(NSString *)postSubject comment:(NSAttributedString *)postComment path:(NSString *)postPicPath thumbPath:(NSString *)postThumbPath pathesArray:(NSArray *)postPathesArray thumbPathesArray:(NSArray *)postThumbPathesArray date:(NSString *)postDate dateAgo:(NSString *)postDateAgo repliesTo:(NSMutableArray *)postRepliesTo mediaType:(DVBPostMediaType)mediaType name:(NSString *)name sage:(BOOL)sage {
    self = [super init];
    if (self) {
        _num = postNum;
        _subject = postSubject;
        _comment = postComment;
        _path = postPicPath;
        _thumbPath = postThumbPath;
        _pathesArray = postPathesArray;
        _thumbPathesArray = postThumbPathesArray;
        _date = postDate;
        _dateAgo = postDateAgo;
        _repliesTo = postRepliesTo;
        _replies = [NSMutableArray array];
        _mediaType = mediaType;
        _name = name;
        _sage = sage;
    }
    return self;
}

@end