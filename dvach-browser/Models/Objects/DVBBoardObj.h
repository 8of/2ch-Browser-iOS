//
//  DVBBoardObj.h
//  dvach-browser
//
//  Created by Andy on 16/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Object for storing information about specific board.
 */
@interface DVBBoardObj : NSObject

/**
 *  Id of the board is simple chort code for fast forwarding to board content without scrolling board list.
 */
@property (strong, nonatomic, readonly) NSString *boardId;
/**
 *  Name of the board, for board listing and (probably) for boardViewController's title.
 */
@property (strong, nonatomic, readonly) NSString *name;

/**
 *  Count of total pages in the board.
 */
@property (assign, nonatomic, readonly) NSUInteger pages;

- (instancetype)initWithId:(NSString *)boardId
                   andName:(NSString *)name;

/**
 *  Initialization of board object with
 *
 *  @param boardId Shortcode of the board.
 *  @param name    Name of the board in Russian.
 *  @param pages   Count of total pages in the board.
 */
- (instancetype)initWithId:(NSString *)boardId
                   andName:(NSString *)name
                  andPages:(NSUInteger)pages;

@end