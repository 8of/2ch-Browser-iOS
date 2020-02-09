//
//  DVBPostViewModel.m
//  dvach-browser
//
//  Created by Andy on 17/12/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBPostViewModel.h"
#import "DVBPost.h"

@implementation DVBPostViewModel

- (instancetype)initWithPost:(DVBPost *)post andIndex:(NSInteger)index
{
  self = [super init];
  if (self) {
    _title = [[NSString alloc] initWithFormat:@"#%ld • %@ • ", (long)(index+1), post.num];
    _num = post.num;
    _text = post.comment;
    _index = index;
    _repliesCount = post.replies.count;
    _thumbs = post.thumbPathesArray;
    _pictures = post.pathesArray;
    _timestamp = post.timestamp;
  }
  return self;
}

- (void)convertToNested
{
  _repliesCount = 0;
}

@end
