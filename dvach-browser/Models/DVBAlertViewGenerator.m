//
//  DVBAlertViewGenerator.m
//  dvach-browser
//
//  Created by Mega on 13/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBAlertViewGenerator.h"
#import "DVBValidation.h"
#import "DVBStatus.h"
#import "DVBConstants.h"

@interface DVBAlertViewGenerator () <UIAlertViewDelegate, UITextFieldDelegate>

@end

@implementation DVBAlertViewGenerator

- (UIAlertView *)alertViewWithTitle:(NSString *)title
                        description:(NSString *)description buttons:(NSArray *)buttons
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
    NSString *enterBoardShortcodeAlertTitle = NSLocalizedString(@"Код доски", @"Заголовок alert'a с полем ввода кодовых букв Борды");
    NSString *enterBoardShortcodeAlertMessage = NSLocalizedString(@"Введите код доски для перемещения её в Избранное", @"Текст alert'a с полем ввода кодовых букв Борды");
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

- (UIAlertView *)alertViewForPassCodeWithIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *enterBoardShortcodeAlertTitle = NSLocalizedString(@"Пасскод", @"Заголовок alert'a с полем ввода для пасскода");
    NSString *enterBoardShortcodeAlertMessage = NSLocalizedString(@"Введите пасскод для отправки сообщений без капчи", @"Текст alert'a с полем ввода пасскода");
    NSString *enterBoardShortcodeAlertCancelButtonText = NSLocalizedString(@"Отмена", @"Кнопка Отмена alert'a с полем ввода пасскода");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:enterBoardShortcodeAlertTitle
                                                        message:enterBoardShortcodeAlertMessage
                                                       delegate:self
                                              cancelButtonTitle:enterBoardShortcodeAlertCancelButtonText
                                              otherButtonTitles:@"OK", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *boardTextField = [alertView textFieldAtIndex:0];
    [boardTextField setKeyboardType:UIKeyboardTypeASCIICapable];
    boardTextField.delegate = self;
    alertView.tag = 2;
    
    return alertView;
}

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSInteger alertTag = alertView.tag;
    id<DVBAlertViewGeneratorDelegate> strongDelegate = _alertViewGeneratorDelegate;
    /**
     *  Detecting OK button pressed or not.
     */
    if ((alertTag == 1) && (buttonIndex == 1))
    {
        UITextField *boardCode = [alertView textFieldAtIndex:0];
        [boardCode resignFirstResponder];
        boardCode= [alertView textFieldAtIndex:0];
        NSString *code = boardCode.text;
        DVBValidation *validationObject = [[DVBValidation alloc] init];

        DVBStatus *status = [DVBStatus sharedStatus];
        /**
         *  checking shortcode for presence of not appropriate symbols
         */
        if ([validationObject checkBoardShortCodeWith:code])
        {
            // check if app now in review or production
            if (status.filterContent)
            {
                /**
                 *  check if board good or bad - last chance for board to stay alive...
                 */
                BOOL isCurrentBoardAmongBadOnes = [validationObject checkBadBoardWithBoard:code];
                if (!isCurrentBoardAmongBadOnes)
                {
                    if ([strongDelegate respondsToSelector:@selector(addBoardWithCode:)])
                    {
                        [strongDelegate addBoardWithCode:code];
                    }
                }
                else
                {
                    NSString *boardNotPermittedAlertTitle = NSLocalizedString(@"Доска запрещена к просмотру", @"Заголовок alert'a  сообщает о том, что конкретная борда не доступна");
                    UIAlertView *alertView = [self alertViewWithTitle:boardNotPermittedAlertTitle
                                                                        description:nil
                                                                            buttons:nil];
                    [alertView show];
                }
            }
            /**
             *  if in production - just add board view
             */
            else
            {
                if ([strongDelegate respondsToSelector:@selector(addBoardWithCode:)])
                {
                    [strongDelegate addBoardWithCode:code];
                }
            }
        }
    }
    else if ((alertTag == 2) && (buttonIndex == 1))
    {
        UITextField *passcodeField = [alertView textFieldAtIndex:0];
        [passcodeField resignFirstResponder];
        NSString *passcode = passcodeField.text;
        
        BOOL isDelegateResponds = [strongDelegate respondsToSelector:@selector(getUsercodeWithCode:)];
        
        if (isDelegateResponds)
        {
            [strongDelegate getUsercodeWithCode:passcode];
        }
    }
}

@end