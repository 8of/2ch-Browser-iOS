//
//  DVBMediaButtonNode.h
//  dvach-browser
//
//  Created by Andy on 21/02/17.
//  Copyright © 2017 8of. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVBMediaButtonNode : ASButtonNode

@property (nonatomic, strong, readonly) NSString *url;

- (instancetype)initWithURL:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
