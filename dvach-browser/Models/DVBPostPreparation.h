//
//  DVBPostPreparation.h
//  dvach-browser
//
//  Created by Andy on 19/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVBPostPreparation : NSObject

// Add 2ch markup to the comment (based on HTML markup
- (NSAttributedString *)commentWithMarkdownWithComments:(NSString *)comment;

@end
