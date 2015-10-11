//
//  DVBDvachWebViewViewController.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 11/10/15.
//  Copyright © 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DVBDvachWebViewViewControllerProtocol <NSObject>

@optional

- (void)reloadAfterWebViewDismissing;

@end

@interface DVBDvachWebViewViewController : UIViewController

- (instancetype)initWithUrlString:(NSString *)urlString andDvachWebViewViewControllerDelegate:(id<DVBDvachWebViewViewControllerProtocol>)dvachWebViewViewControllerDelegate;

@property (nonatomic, weak) id<DVBDvachWebViewViewControllerProtocol> dvachWebViewViewControllerDelegate;

@end
