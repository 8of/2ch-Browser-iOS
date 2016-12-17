//
//  DVBPostViewModel.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 17/12/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DVBPost;

@interface DVBPostViewModel : NSObject

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSAttributedString *text;
@property (nonatomic, assign, readonly) NSInteger index;
@property (nonatomic, assign, readonly) NSInteger repliesCount;
@property (nonatomic, strong, readonly) NSArray <NSString *> *thumbs;
@property (nonatomic, strong, readonly) NSArray <NSString *> *pictures;

- (instancetype)initWithPost:(DVBPost *)post andIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
