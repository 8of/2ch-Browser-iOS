//
//  DVBCommonTableViewController.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 13/06/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBAlertViewGenerator.h"

#import "DVBCommonTableViewController.h"

@interface DVBCommonTableViewController ()

@end

@implementation DVBCommonTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSUserDefaultsDidChangeNotification
                                                  object:nil];
}

- (void)defaultsChanged
{
    UIViewController *vc = [[self.navigationController viewControllers] firstObject];
    if([vc isEqual: self ]) {
        DVBAlertViewGenerator *alertGenerator = [[DVBAlertViewGenerator alloc] init];
        NSString *restartAppAlertTitle = NSLocalizedString(@"Настройки изменены", @"Настройки изменены");
        NSString *restartAppAlertDescription = NSLocalizedString(@"Для правильной работы закройте приложение и запустите его заново.", @"Для правильной работы закройте приложение и запустите его заново.");
        UIAlertView *alertView = [alertGenerator alertViewWithTitle:restartAppAlertTitle description:restartAppAlertDescription buttons:@[@"OK"]];
        [alertView show];
    }
}

@end
