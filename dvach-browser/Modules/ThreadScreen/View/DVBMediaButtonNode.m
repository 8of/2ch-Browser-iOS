//
//  DVBMediaButtonNode.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 21/02/17.
//  Copyright © 2017 8of. All rights reserved.
//

#import "DVBMediaButtonNode.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVBMediaButtonNode

- (instancetype)initWithURL:(NSString *)url
{
  self = [super init];
  if (self) {
    _url = url;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
