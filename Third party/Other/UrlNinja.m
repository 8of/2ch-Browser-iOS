//
//  UrlNinja.m
//  m2ch
//
//  Created by Alexander Tewpin on 06/06/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "UrlNinja.h"

@implementation UrlNinja

- (id)initWithUrl:(NSURL *)url {
    
    NSString *basicUrl = @"2ch.hk";
    
    //проверить хост, если он существует и левый, то сразу возврат
    if (!([[url host] isEqualToString:basicUrl] || [[url host] isEqualToString:[@"www." stringByAppendingString:basicUrl]]) && [url host]) {
        self.type = externalLink;
        return self;
    }
    
    //компоненты урла
    NSArray *source = [url pathComponents];
    
    if (source.count > 1) {
        self.boardId = source[1];
    }
    
    if (source.count > 3) {
        self.threadId = source[3];
    }
    
    //проверка на валидность полей
    NSRegularExpression *boardCheck = [[NSRegularExpression alloc]initWithPattern:@"[a-z, A-Z]+" options:0 error:nil];
    NSRegularExpression *threadCheck = [[NSRegularExpression alloc]initWithPattern:@"[0-9]+.html" options:0 error:nil];
    NSRegularExpression *postCheck = [[NSRegularExpression alloc]initWithPattern:@"[0-9]+" options:0 error:nil];
    
    if (self.boardId) {
        NSTextCheckingResult *boardResult = [boardCheck firstMatchInString:self.boardId options:0 range:NSMakeRange(0, self.boardId.length)];
        if (boardResult.range.length != self.boardId.length) {
            self.type = externalLink;
            return self;
        }
    }
    
    if (self.threadId) {
        NSTextCheckingResult *threadResult = [threadCheck firstMatchInString:self.threadId options:0 range:NSMakeRange(0, self.threadId.length)];
        if (threadResult.range.length != self.threadId.length) {
            self.type = externalLink;
            return self;
        }
        //отпиливаем .html
        self.threadId = [self.threadId substringWithRange:NSMakeRange(0, self.threadId.length-5)];
    }
    
    if (self.postId) {
        NSTextCheckingResult *postResult = [postCheck firstMatchInString:self.postId options:0 range:NSMakeRange(0, self.postId.length)];
        if (postResult.range.length != self.postId.length) {
            self.type = externalLink;
            return self;
        }
    }
    
    //присваивание и проверка на валидность количества компонентов
    self.postId = [url fragment];
    
    if (self.boardId && self.threadId && self.postId && source.count == 4) {
        self.type = boardThreadPostLink;
        return self;
    } else if (self.boardId && self.threadId && source.count == 4) {
        self.type = boardThreadLink;
        return self;
    } else if (self.boardId && source.count == 2) {
        self.type = boardLink;
        return self;
    } else {
        self.type = externalLink;
    }
    
    return self;
}

+ (id)unWithUrl:(NSURL *)url {
    return [[UrlNinja alloc]initWithUrl:url];
}


@end
