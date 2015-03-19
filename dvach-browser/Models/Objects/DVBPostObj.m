//
//  DVBPostObj.m
//  dvach-browser
//
//  Created by Andy on 13/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBPostObj.h"

@implementation DVBPostObj

- (instancetype)initWithNum:(NSString *)postNum
                    subject:(NSString *)postSubject
                    comment:(NSAttributedString *)postComment
                       path:(NSString *)postPicPath
                  thumbPath:(NSString *)postThumbPath {
    self = [super init];
    if (self) {
        _num = postNum;
        _subject = postSubject;
        _comment = postComment;
        _path = postPicPath;
        _thumbPath = postThumbPath;
    }
    return self;
}

@end