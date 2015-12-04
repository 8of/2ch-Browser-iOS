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
NSString *const DVACH_BASE_URL = @"https://2ch.hk/";
NSString *const DVACH_BASE_URL_WITHOUT_SCHEME = @"2ch.hk/";
NSString *const DVACH_BASE_URL_WITHOUT_SCHEME_FOR_URL_NINJA = @"2ch.hk";
NSString *const DVACH_BASE_URL_WITHOUT_SCHEME_FOR_URL_NINJA_HK = @"2ch.hk";
NSString *const GET_CAPTCHA_KEY_URL = @"https://2ch.hk/makaba/captcha.fcgi";
NSString *const REPORT_THREAD_URL = @"https://2ch.hk/makaba/makaba.fcgi";

NSString *const REAL_ADDRESS_FOR_BOARDS_LIST = @"https://2ch.hk/makaba/mobile.fcgi?task=get_boards";
NSString *const URL_TO_GET_USERCODE = @"https://2ch.hk/makaba/makaba.fcgi";
NSString *const URL_TO_CHECK_REVIEW_STATUS = @"http://8of.org/2ch/status2.json";

// Network
NSString *const NETWORK_HEADER_USERAGENT_KEY = @"User-Agent";

// Keys
NSString *const DVACH_RECAPTCHA_KEY = @"6LcM2P4SAAAAAD97nF449oigatS5hPCIgt8AQanz";

// Settings
NSString *const SETTING_ENABLE_DARK_THEME = @"enableDarkTheme";
NSString *const SETTING_ENABLE_LITTLE_BODY_FONT = @"enableLittleBodyFont";
NSString *const SETTING_ENABLE_TRAFFIC_SAVINGS = @"enableTrafficSavings";
NSString *const SETTING_CLEAR_THREADS = @"clearThreads";
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
NSString *const STORYBOARD_ID_CAPTCHA_VIEW_CONTROLLER = @"DVBCaptchaViewController";
NSString *const STORYBOARD_ID_WEBVIEW_VIEW_CONTROLLER = @"DVBDvachWebViewViewController";

// Segues
NSString *const SEGUE_TO_EULA = @"segueToEula";
NSString *const SEGUE_TO_BOARD = @"segueToBoard";
NSString *const SEGUE_TO_THREAD = @"segueToThread";
NSString *const SEGUE_TO_NEW_THREAD = @"segueToNewThread";
NSString *const SEGUE_TO_NEW_THREAD_IOS_7 = @"segueToThreadiOS7";
NSString *const SEGUE_TO_NEW_POST = @"segueToNewPost";
NSString *const SEGUE_TO_NEW_POST_IOS_7 = @"segueToNewPostiOS7";
NSString *const SEGUE_DISMISS_TO_THREAD = @"dismissWithCancelToThreadSegue";
NSString *const SEGUE_DISMISS_TO_NEW_THREAD = @"dismissWithCancelToNewThreadSegue";

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

// Notifications
NSString  *const NOTIFICATION_NAME_BOOKMARK_THREAD = @"kNotificationBookmarkThread";
