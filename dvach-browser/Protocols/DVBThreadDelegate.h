//
//  DVBThreadDelegate.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 18/12/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class UrlNinja;

NS_ASSUME_NONNULL_BEGIN

@protocol DVBThreadDelegate <NSObject>

- (void)openGalleryWIthUrl:(NSString *)url;
- (void)quotePostIndex:(NSInteger)index andText:(nullable NSString *)text;
- (void)showAnswersFor:(NSInteger)index;
- (void)shareWithUrl:(NSString *)url;
- (BOOL)isLinkInternalWithLink:(UrlNinja *)url;
/// Open single post
- (void)openPostWithUrlNinja:(UrlNinja *)urlNinja;
/// Open whole new thread
- (void)openThreadWithUrlNinja:(UrlNinja *)urlNinja;

@end

NS_ASSUME_NONNULL_END
