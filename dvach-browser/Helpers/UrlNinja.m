//
//  UrlNinja.m
//  m2ch
//
//  Created by Alexander Tewpin on 06/06/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "UrlNinja.h"
#import "DVBThreadViewController.h"

@implementation UrlNinja

- (id)initWithUrl:(NSURL *)url
{
    self = [super init];

    if (self) {
    
        NSString *basicUrlPm = [DVBUrls baseWithoutSchemeForUrlNinja];
        NSString *basicUrlHk = [DVBUrls baseWithoutSchemeForUrlNinjaHk];
        
        // Check host - if it's not 2ch - just return external type
        if (!([url.host isEqualToString:basicUrlPm] ||
              [url.host isEqualToString:basicUrlHk] ||
              [url.host isEqualToString:[@"www." stringByAppendingString:basicUrlPm]] ||
              [url.host isEqualToString:[@"www." stringByAppendingString:basicUrlHk]]) &&
            url.host) {
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

    }

    return self;
}

+ (id)unWithUrl:(NSURL *)url
{
    return [[UrlNinja alloc] initWithUrl:url];
}

- (BOOL)isLinkInternalWithLink:(UrlNinja *)url andThreadNum:(NSString *)threadNum andBoardCode:(NSString *)boardCode
{
    if (!_urlOpener) { return NO; }
    switch (url.type) {
        case boardLink: { // Open board
            /*
             BoardViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BoardTag"];
             controller.boardId = urlNinja.boardId;
             [self.navigationController pushViewController:controller animated:YES];
             */

            return NO;

            break;
        }
        case boardThreadLink: { // Open another thread
            if ([_urlOpener respondsToSelector:@selector(openThreadWithUrlNinja:)]) {
                [_urlOpener openThreadWithUrlNinja:url];
            }

            break;
        }
        case boardThreadPostLink: {

            // if we do not have boardId of threadNum assidned - we take them from passed url
            if (!threadNum) {
                threadNum = url.threadId;
            }
            if (!boardCode) {
                boardCode = url.boardId;
            }

            // If its the same thread - open it locally from existing posts
            if ([threadNum isEqualToString:url.threadId] && [boardCode isEqualToString:url.boardId]) {
                if ([_urlOpener respondsToSelector:@selector(openPostWithUrlNinja:)]) {
                    [_urlOpener openPostWithUrlNinja:url];
                }

                return YES;
            }
            else { // Open another thread
                if ([_urlOpener respondsToSelector:@selector(openThreadWithUrlNinja:)]) {
                    [_urlOpener openThreadWithUrlNinja:url];
                }
            }
        }
            break;
        default: {

            return NO;

            break;
        }
    }
    
    return YES;
}

@end
