//
//  DVBDismissSegue.m
//  dvach-browser
//
//  Created by Andy on 26/01/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBDismissSegue.h"

@implementation DVBDismissSegue

// Dismiss segue back to the thread
- (void)perform {
    UIViewController *sourceViewController = self.sourceViewController;
    [sourceViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end