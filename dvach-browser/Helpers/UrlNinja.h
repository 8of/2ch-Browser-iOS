//
//  UrlNinja.h
//  m2ch
//
//  Created by Alexander Tewpin on 06/06/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UrlNinja : NSObject

typedef NS_ENUM(NSUInteger, linkType) {
    externalLink = 0,
    boardLink = 1,
    boardThreadLink = 2,
    boardThreadPostLink = 3
};

@property (nonatomic, assign) enum linkType type;
@property (nonatomic, strong) NSString *boardId;
@property (nonatomic, strong) NSString *threadId;
@property (nonatomic, strong) NSString *postId;
@property (nonatomic, strong) NSString *threadTitle;
@property (nonatomic, strong) id urlOpener;

- (id) initWithUrl:(NSURL *)url;
+ (id) unWithUrl:(NSURL *)url;

- (BOOL)isLinkInternalWithLink:(UrlNinja *)url andThreadNum:(NSString *)threadNum andBoardCode:(NSString *)boardCode;

@end
