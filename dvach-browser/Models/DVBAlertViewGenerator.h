//
//  DVBAlertViewGenerator.h
//  dvach-browser
//
//  Created by Mega on 13/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIAlertController.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVBAlertViewGeneratorDelegate <NSObject>

- (void)addBoardWithCode:(NSString *)code;

@end

@interface DVBAlertViewGenerator : NSObject

@property (nonatomic, weak) id<DVBAlertViewGeneratorDelegate> alertViewGeneratorDelegate;

+ (UIAlertController *)ageCheckAlert;

- (UIAlertController *)boardCodeAlert;

@end

NS_ASSUME_NONNULL_END
