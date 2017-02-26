//
//  DVBconstants.h
//  dvach-browser
//
//  Created by Andy on 05/11/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

// iOS version checkers
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

// Sizes
#define ONE_PIXEL (1.0f / [[UIScreen mainScreen] scale])
// Colors
#define DVACH_COLOR [UIColor colorWithRed:(255.0/255.0) green:(139.0/255.0) blue:(16.0/255.0) alpha:1.0]
#define DVACH_COLOR_CG [[UIColor colorWithRed:(255.0/255.0) green:(139.0/255.0) blue:(16.0/255.0) alpha:1.0] CGColor]
#define DVACH_COLOR_HIGHLIGHTED [UIColor colorWithRed:(255.0/255.0) green:(139.0/255.0) blue:(16.0/255.0) alpha:0.3]
#define DVACH_COLOR_HIGHLIGHTED_CG [[UIColor colorWithRed:(255.0/255.0) green:(139.0/255.0) blue:(16.0/255.0) alpha:0.3] CGColor]
#define THUMBNAIL_GREY_BORDER [[UIColor colorWithRed:(151.0/255.0) green:(151.0/255.0) blue:(151.0/255.0) alpha:1.0] CGColor]
#define CELL_SEPARATOR_COLOR [UIColor colorWithRed:(200.0/255.0) green:(200.0/255.0) blue:(204.0/255.0) alpha:1.0]

// Colors - Dark theme
#define CELL_BACKGROUND_COLOR [UIColor colorWithRed:(35.0/255.0) green:(35.0/255.0) blue:(37.0/255.0) alpha:1.0]
#define DARK_CELL_TEXT_COLOR [UIColor colorWithRed:(199.0/255.0) green:(199.0/255.0) blue:(204.0/255.0) alpha:1.0]
#define CELL_TEXT_COLOR [UIColor colorWithRed:(199.0/255.0) green:(199.0/255.0) blue:(204.0/255.0) alpha:1.0]
#define CELL_SEPARATOR_COLOR_BLACK [UIColor colorWithRed:(24.0/255.0) green:(24.0/255.0) blue:(26.0/255.0) alpha:1.0]
#define CELL_TEXT_SPOILER_COLOR [UIColor colorWithRed:(199.0/255.0) green:(199.0/255.0) blue:(204.0/255.0) alpha:0.3]

// URL schemes
FOUNDATION_EXPORT NSString *const HTTPS_SCHEME;
FOUNDATION_EXPORT NSString *const HTTP_SCHEME;

// URLS
FOUNDATION_EXPORT NSString *const DVACH_DOMAIN;

// Network
FOUNDATION_EXPORT NSString *const NETWORK_HEADER_USERAGENT_KEY;

// Settings
FOUNDATION_EXPORT NSString *const SETTING_ENABLE_DARK_THEME;
FOUNDATION_EXPORT NSString *const SETTING_ENABLE_INTERNAL_WEBM_PLAYER;
FOUNDATION_EXPORT NSString *const SETTING_CLEAR_THREADS;
FOUNDATION_EXPORT NSString *const SETTING_BASE_DOMAIN;
FOUNDATION_EXPORT NSString *const SETTING_FORCE_CAPTCHA;
FOUNDATION_EXPORT NSString *const USER_AGREEMENT_ACCEPTED;
FOUNDATION_EXPORT NSString *const PASSCODE;
FOUNDATION_EXPORT NSString *const USERCODE;
FOUNDATION_EXPORT NSString *const DEFAULTS_REVIEW_STATUS;
FOUNDATION_EXPORT NSString *const DEFAULTS_USERAGENT_KEY;

// Storyboards
FOUNDATION_EXPORT NSString *const STORYBOARD_NAME_MAIN;
FOUNDATION_EXPORT NSString *const STORYBOARD_NAME_WEBVIEWS;

// Storyboard VC ID's
FOUNDATION_EXPORT NSString *const STORYBOARD_ID_THREAD_VIEW_CONTROLLER;
FOUNDATION_EXPORT NSString *const STORYBOARD_ID_WEBVIEW_VIEW_CONTROLLER;
FOUNDATION_EXPORT NSString *const STORYBOARD_ID_CREATE_POST_VIEW_CONTROLLER;

// Segues
FOUNDATION_EXPORT NSString *const SEGUE_TO_EULA;
FOUNDATION_EXPORT NSString *const SEGUE_TO_BOARD;
FOUNDATION_EXPORT NSString *const SEGUE_TO_THREAD;
FOUNDATION_EXPORT NSString *const SEGUE_TO_NEW_THREAD_IPAD;
FOUNDATION_EXPORT NSString *const SEGUE_TO_NEW_THREAD_IPHONE;
FOUNDATION_EXPORT NSString *const SEGUE_TO_NEW_POST;
FOUNDATION_EXPORT NSString *const SEGUE_TO_NEW_POST_IOS_7;
FOUNDATION_EXPORT NSString *const SEGUE_DISMISS_TO_THREAD;

// Cells
FOUNDATION_EXPORT NSString *const BOARD_CELL_IDENTIFIER;
FOUNDATION_EXPORT NSString *const DVB_BOARDVIEWCONTROLLER_IDENTIFIER;
FOUNDATION_EXPORT NSString *const THREAD_CELL_IDENTIFIER;
FOUNDATION_EXPORT NSString *const POST_CELL_IDENTIFIER;

// Files
FOUNDATION_EXPORT NSString *const FILENAME_THUMB_IMAGE_PLACEHOLDER;

// Errors
FOUNDATION_EXPORT NSString *const ERROR_DOMAIN_APP;
FOUNDATION_EXPORT NSString *const ERROR_USERINFO_KEY_IS_DDOS_PROTECTION;
FOUNDATION_EXPORT NSString *const ERROR_USERINFO_KEY_URL_TO_CHECK_IN_BROWSER;
FOUNDATION_EXPORT NSInteger const ERROR_CODE_DDOS_CHECK;
FOUNDATION_EXPORT NSString *const ERROR_OPERATION_HEADER_KEY_REFRESH;
FOUNDATION_EXPORT NSString *const ERROR_OPERATION_REFRESH_VALUE_SEPARATOR;
FOUNDATION_EXPORT NSString *const WEBVIEW_PART_OF_THE_PAGE_TO_CHECK_MAIN_PAGE;

// Sizes
FOUNDATION_EXPORT NSInteger const PREVIEW_IMAGE_SIZE;
FOUNDATION_EXPORT NSInteger const PREVIEW_IMAGE_SIZE_IPAD;
FOUNDATION_EXPORT NSInteger const PREVIEW_ROW_DEFAULT_HEIGHT;
FOUNDATION_EXPORT NSInteger const PREVIEW_ROW_DEFAULT_HEIGHT_IPAD;

// Notifications
FOUNDATION_EXPORT NSString *const NOTIFICATION_NAME_BOOKMARK_THREAD;

// Keys
FOUNDATION_EXPORT NSString *const AP_CAPTCHA_PUBLIC_KEY;
FOUNDATION_EXPORT NSString *const AP_CAPTCHA_PRIVATE_KEY;

// Etc
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
