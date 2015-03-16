//
//  DVBComment.h
//  dvach-browser
//
//  Created by Mega on 28/01/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

/**
 *  Comment, shared across all app
 */

#import <Foundation/Foundation.h>

@interface DVBComment : NSObject
{
    NSString *comment;
}

@property (nonatomic, retain) NSString *comment;

+ (id)sharedComment;

@end
