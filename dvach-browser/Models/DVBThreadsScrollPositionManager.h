//
//  DVBThreadsScrollPositionManager.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 09/05/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVBThreadsScrollPositionManager : NSObject
{
    NSMutableDictionary *threads;
    NSMutableDictionary *threadPostCounts;
}

/// Dicitonary with keys - thread numbers and values - NSNUmbers
@property (nonatomic, strong) NSMutableDictionary *threads;
/// Dicitonary with keys - thread numbers and values - NSNUmbers - post count in specific thread
@property (nonatomic, strong) NSMutableDictionary *threadPostCounts;

+ (id)sharedThreads;

@end
