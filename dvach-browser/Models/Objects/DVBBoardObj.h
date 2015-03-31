//
//  DVBBoardObj.h
//  dvach-browser
//
//  Created by Andy on 16/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/**
 *  Object for storing information about specific board.
 */
@interface DVBBoardObj : NSManagedObject

/**
 *  Id of the board is simple chort code for fast forwarding to board content without scrolling board list.
 */
@property (strong, nonatomic) NSString *boardId;
/**
 *  Name of the board, for board listing and (probably) for boardViewController's title.
 */
@property (strong, nonatomic) NSString *name;

/**
 *  Count of total pages in the board.
 */
@property (assign, nonatomic) NSUInteger pages;

@end
