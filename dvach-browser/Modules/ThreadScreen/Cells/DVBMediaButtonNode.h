//
//  DVBMediaButtonNode.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 21/02/17.
//  Copyright © 2017 8of. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface DVBMediaButtonNode : ASButtonNode

@property (nonatomic, strong, readonly) NSString *url;

- (instancetype)initWithURL:(NSString *)url;

@end
