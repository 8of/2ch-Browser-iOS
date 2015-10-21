//
//  DVBCommonTableViewController.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 13/06/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DVBCommonTableViewController : UITableViewController

/// Handle Clouda / DDoS protection errors
- (void)handleError:(NSError *)error;
/// Only for launching from subclasses, blank method, override it
- (void)reloadAfterWebViewDismissing;

@end
