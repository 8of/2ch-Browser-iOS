//
//  DVBCommonTableViewController.m
//  dvach-browser
//
//  Created by Andy on 13/06/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBCommon.h"
#import "DVBConstants.h"
#import "DVBCommonTableViewController.h"

@interface DVBCommonTableViewController ()

@property (nonatomic, strong) NSIndexPath *savedSelectedIndexPath;

@end

@implementation DVBCommonTableViewController

#pragma mark - Fixes for right cells deselect behaviour

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.savedSelectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (self.savedSelectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:self.savedSelectedIndexPath animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.savedSelectedIndexPath = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.savedSelectedIndexPath) {
        [self.tableView selectRowAtIndexPath:self.savedSelectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

@end
