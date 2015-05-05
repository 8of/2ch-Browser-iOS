//
//  DVBAlertViewGenerator.m
//  dvach-browser
//
//  Created by Mega on 13/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBAlertViewGenerator.h"
#import "DVBValidation.h"
#import "DVBConstants.h"

@interface DVBAlertViewGenerator () <UIAlertViewDelegate, UITextFieldDelegate>

@end

@implementation DVBAlertViewGenerator

- (UIAlertView *)alertViewWithTitle:(NSString *)title description:(NSString *)description buttons:(NSArray *)buttons
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:description
                                                           delegate:_alertViewGeneratorDelegate
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];

    return alertView;
}

- (UIAlertView *)alertViewForBoardCode
{
    NSString *enterBoardShortcodeAlertTitle = NSLocalizedString(@"Добавить в избранное", @"Заголовок alert'a с полем ввода кодовых букв Борды");
    NSString *enterBoardShortcodeAlertMessage = NSLocalizedString(@"Введите код доски, чтобы добавить ее в избранное", @"Текст alert'a с полем ввода кодовых букв Борды");
    NSString *enterBoardShortcodeAlertCancelButtonText = NSLocalizedString(@"Отмена", @"Кнопка Отмена alert'a с полем ввода кодовых букв Борды");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:enterBoardShortcodeAlertTitle
                                                        message:enterBoardShortcodeAlertMessage
                                                       delegate:self
                                              cancelButtonTitle:enterBoardShortcodeAlertCancelButtonText
                                              otherButtonTitles:@"OK", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *boardTextField = [alertView textFieldAtIndex:0];
    [boardTextField setKeyboardType:UIKeyboardTypeASCIICapable];
    boardTextField.delegate = self;
    alertView.tag = 1;

    return alertView;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSInteger alertTag = alertView.tag;
    id<DVBAlertViewGeneratorDelegate> strongDelegate = _alertViewGeneratorDelegate;
    /**
     *  Detecting OK button pressed or not.
     */
    if ((alertTag == 1) && (buttonIndex == 1)) {
        UITextField *boardCode = [alertView textFieldAtIndex:0];
        [boardCode resignFirstResponder];
        boardCode= [alertView textFieldAtIndex:0];
        NSString *code = boardCode.text;
        DVBValidation *validation = [[DVBValidation alloc] init];
        /**
         *  checking shortcode for presence of not appropriate symbols
         */
        if ([validation checkBoardShortCodeWith:code]) {

            if ([strongDelegate respondsToSelector:@selector(addBoardWithCode:)]) {
                [strongDelegate addBoardWithCode:code];
            }
        }
    }
}

@end