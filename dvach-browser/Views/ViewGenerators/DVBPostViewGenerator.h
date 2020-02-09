//
//  DVBPostViewGenerator.h
//  dvach-browser
//
//  Created by Andy on 17/12/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVBPostViewGenerator : NSObject

+ (ASDisplayNode *)borderNode;
+ (ASTextNode *)titleNode;
+ (ASTextNode *)textNodeWithText:(NSAttributedString *)text;
+ (ASNetworkImageNode *)mediaNodeWithURL:(NSString *)url isWebm:(BOOL)isWebm;
+ (ASButtonNode *)answerButton;
+ (ASButtonNode *)showAnswersButtonWithCount:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
