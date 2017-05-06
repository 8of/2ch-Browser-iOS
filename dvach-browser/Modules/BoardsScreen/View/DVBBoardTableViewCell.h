//
//  DVBBoardTableViewCell.h
//  dvach-browser
//
//  Created by Mega on 13/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DVBConstants.h"

@interface DVBBoardTableViewCell : UITableViewCell

- (void)prepareCellWithId:(NSString *)boardId andBoardName:(NSString *)boardName;

@end
