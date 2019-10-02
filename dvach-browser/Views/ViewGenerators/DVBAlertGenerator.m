//
//  DVBAlertGenerator.m
//  dvach-browser
//
//  Created by Mega on 13/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBCommon.h"
#import "DVBAlertGenerator.h"
#import "DVBValidation.h"
#import "DVBConstants.h"
#import "DVBDefaultsManager.h"

@implementation DVBAlertGenerator

+ (UIAlertController *)ageCheckAlert {
  NSString *title = NSLS(@"ALERT_AGE_CHECK_TITLE");
  NSString *message = NSLS(@"ALERT_AGE_CHECK_MESSAGE");
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLS(@"BUTTON_CANCEL")
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * _Nonnull action) {}];
  [alertController addAction:cancelAction];
  UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLS(@"ALERT_AGE_CHECK_CONFIRM")
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * _Nonnull action)
                             {
                               [[NSUserDefaults standardUserDefaults] setBool:YES
                                                                       forKey:DEFAULTS_AGE_CHECK_STATUS];
                               [[NSUserDefaults standardUserDefaults] synchronize];
                             }];
  [alertController addAction:okAction];
  return alertController;
}

+ (UIAlertController *)webmDeprecatedAlert {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:NSLS(@"DEPRECATED")
                                          message:NSLS(@"DEPRECATED")
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLS(@"BUTTON_CANCEL")
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {}];
    [alertController addAction:cancelAction];
    return alertController;
}

- (UIAlertController *)boardCodeAlert {
  NSString *title = NSLS(@"ALERT_BOARD_CODE_TITLE");
  NSString *message = NSLS(@"ALERT_BOARD_CODE_MESSAGE");
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
  [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
    if ([DVBDefaultsManager isDarkMode]) {
      textField.keyboardAppearance = UIKeyboardAppearanceDark;
    }
  }];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLS(@"BUTTON_CANCEL")
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * _Nonnull action) {}];
  [alertController addAction:cancelAction];
  weakify(self);
  UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLS(@"BUTTON_OK")
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * _Nonnull action)
  {
    UITextField *textField = alertController.textFields.firstObject;
    if (!textField) {
      return;
    }
    NSString *code = textField.text;
    [textField resignFirstResponder];
    strongify(self);
    DVBValidation *validation = [[DVBValidation alloc] init];
    // checking shortcode for presence of not appropriate symbols
    if ([validation checkBoardShortCodeWith:code]) {
      if ([self.alertGeneratorDelegate respondsToSelector:@selector(addBoardWithCode:)]) {
        [self.alertGeneratorDelegate addBoardWithCode:code];
      }
    }
  }];
  [alertController addAction:okAction];
  return alertController;
}

@end
