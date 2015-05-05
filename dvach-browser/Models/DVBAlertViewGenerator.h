//
//  DVBAlertViewGenerator.h
//  dvach-browser
//
//  Created by Mega on 13/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol DVBAlertViewGeneratorDelegate <NSObject>

@optional
- (void)addBoardWithCode:(NSString *)code;
- (void)getUsercodeWithCode:(NSString *)passcode;
@end

@interface DVBAlertViewGenerator : NSObject

@property (nonatomic, weak) id<DVBAlertViewGeneratorDelegate> alertViewGeneratorDelegate;

- (UIAlertView *)alertViewWithTitle:(NSString *)title
                        description:(NSString *)description
                            buttons:(NSArray *)buttons;
- (UIAlertView *)alertViewForBoardCode;

@end