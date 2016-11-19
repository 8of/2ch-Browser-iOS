//
//  DVBconstants.m
//  dvach-browser
//
//  Created by Andy on 05/11/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBConstants.h"

// URL schemes
NSString *const HTTPS_SCHEME = @"https://";
NSString *const HTTP_SCHEME = @"http://";
// URLs
NSString *const DVACH_DOMAIN = @"2ch.hk";

// Network
NSString *const NETWORK_HEADER_USERAGENT_KEY = @"User-Agent";

// Settings
NSString *const SETTING_ENABLE_DARK_THEME = @"enableDarkTheme";
NSString *const SETTING_ENABLE_LITTLE_BODY_FONT = @"enableLittleBodyFont";
NSString *const SETTING_ENABLE_INTERNAL_WEBM_PLAYER = @"internalWebmPlayer";
NSString *const SETTING_ENABLE_TRAFFIC_SAVINGS = @"enableTrafficSavings";
NSString *const SETTING_CLEAR_THREADS = @"clearThreads";
NSString *const SETTING_BASE_DOMAIN = @"domain";
NSString *const USER_AGREEMENT_ACCEPTED = @"userAgreementAccepted";
NSString *const PASSCODE = @"passcode";
NSString *const USERCODE = @"usercode";
NSString *const DEFAULTS_REVIEW_STATUS = @"defaultReviewStatus";
NSString *const DEFAULTS_USERAGENT_KEY = @"UserAgent";

// Storyboards
NSString *const STORYBOARD_NAME_MAIN = @"Main";
NSString *const STORYBOARD_NAME_WEBVIEWS = @"WebViews";

// Storyboard VC ID's
NSString *const STORYBOARD_ID_THREAD_VIEW_CONTROLLER = @"DVBThreadViewController";
NSString *const STORYBOARD_ID_WEBVIEW_VIEW_CONTROLLER = @"DVBDvachWebViewViewController";
NSString *const STORYBOARD_ID_CREATE_POST_VIEW_CONTROLLER = @"DVBCreateViewController";

// Segues
NSString *const SEGUE_TO_EULA = @"segueToEula";
NSString *const SEGUE_TO_BOARD = @"segueToBoard";
NSString *const SEGUE_TO_THREAD = @"segueToThread";
NSString *const SEGUE_TO_NEW_THREAD_IPAD = @"segueToNewThread";
NSString *const SEGUE_TO_NEW_THREAD_IPHONE = @"segueToThreadiOS7";
NSString *const SEGUE_TO_NEW_POST = @"segueToNewPost";
NSString *const SEGUE_TO_NEW_POST_IOS_7 = @"segueToNewPostiOS7";
NSString *const SEGUE_DISMISS_TO_THREAD = @"dismissWithCancelToThreadSegue";

// Cells
NSString *const BOARD_CELL_IDENTIFIER = @"boardEntryCell";
NSString *const DVB_BOARDVIEWCONTROLLER_IDENTIFIER = @"DVBBoardViewController";
NSString *const THREAD_CELL_IDENTIFIER = @"threadCell";
NSString *const POST_CELL_IDENTIFIER = @"postCell";

// Files
NSString *const FILENAME_THUMB_IMAGE_PLACEHOLDER = @"Noimage.png";

// Errors
NSString *const ERROR_DOMAIN_APP = @"com.8of.dvach-browser.error";
NSString *const ERROR_USERINFO_KEY_IS_DDOS_PROTECTION = @"NSErrorIsDDoSProtection";
NSString *const ERROR_USERINFO_KEY_URL_TO_CHECK_IN_BROWSER = @"NSErrorUrlToCheckInBrowser";
NSInteger const ERROR_CODE_DDOS_CHECK = 1001;
NSString *const ERROR_OPERATION_HEADER_KEY_REFRESH = @"refresh";
NSString *const ERROR_OPERATION_REFRESH_VALUE_SEPARATOR = @"URL=/";
NSString *const WEBVIEW_PART_OF_THE_PAGE_TO_CHECK_MAIN_PAGE = @".ч";

// Sizes
NSInteger const PREVIEW_IMAGE_SIZE = 64;
NSInteger const PREVIEW_IMAGE_SIZE_IPAD = 100;
NSInteger const PREVIEW_ROW_DEFAULT_HEIGHT = 84;
NSInteger const PREVIEW_ROW_DEFAULT_HEIGHT_IPAD = 120;

// Notifications
NSString *const NOTIFICATION_NAME_BOOKMARK_THREAD = @"kNotificationBookmarkThread";

// Keys
NSString *const AP_CAPTCHA_PUBLIC_KEY = @"BiIWoUVlqn5AquNm1NY832D4Ljj0IOzR";
NSString *const AP_CAPTCHA_PRIVATE_KEY = @"";
