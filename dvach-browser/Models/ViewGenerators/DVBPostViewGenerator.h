//
//  DVBPostViewGenerator.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 17/12/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVBPostViewGenerator : NSObject

+ (ASDisplayNode *)borderNode;
+ (ASTextNode *)titleNodeWithText:(NSString *)text;
+ (ASTextNode *)textNodeWithText:(NSAttributedString *)text;
+ (ASNetworkImageNode *)mediaNodeWithURL:(NSString *)url;
+ (ASButtonNode *)answerButton;
+ (ASButtonNode *)answerWithQuoteButton;
+ (ASButtonNode *)showAnswersButtonWithCount:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
