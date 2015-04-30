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
NSString *const GOOGLE_CHROME_HTTPS_SCHEME = @"googlechromes://";
NSString *const GOOGLE_CHROME_HTTP_SCHEME = @"googlechrome://";

// URLs
NSString *const STATUS_REQUEST_ADDRESS = @"http://8of.org/2ch/status.json";
NSString *const DVACH_BASE_URL = @"https://2ch.hk/";
NSString *const DVACH_BASE_URL_WITHOUT_SCHEME = @"2ch.hk/";
NSString *const COMPLAINT_URL = @"http://8of.org/2ch/tickets";
NSString *const GET_CAPTCHA_KEY_URL = @"https://2ch.hk/makaba/captcha.fcgi";
NSString *const GET_CAPTCHA_IMAGE_URL = @"http://captcha.yandex.net/image?key=%@";

// settings
NSString *const USER_AGREEMENT_ACCEPTED = @"userAgreementAccepted";
NSString *const OPEN_EXTERNAL_LINKS_IN_CHROME = @"openExternalLinksInChrome";
NSString *const PASSCODE = @"passcode";
NSString *const USERCODE = @"usercode";
NSString *const BOARDS_LIST_VERSION = @"boardsListVersion";

// segues
NSString *const SEGUE_TO_EULA = @"segueToEula";
NSString *const SEGUE_TO_BOARD = @"segueToBoard";
NSString *const SEGUE_TO_THREAD = @"segueToThread";
NSString *const SEGUE_TO_NEW_THREAD = @"segueToNewThread";
NSString *const SEGUE_TO_NEW_THREAD_IOS_7 = @"segueToThreadiOS7";
NSString *const SEGUE_TO_NEW_POST = @"segueToNewPost";
NSString *const SEGUE_TO_NEW_POST_IOS_7 = @"segueToNewPostiOS7";
NSString *const SEGUE_DISMISS_TO_THREAD = @"dismissWithCancelToThreadSegue";
NSString *const SEGUE_DISMISS_TO_NEW_THREAD = @"dismissWithCancelToNewThreadSegue";

// cells
NSString *const BOARD_CELL_IDENTIFIER = @"boardEntryCell";
NSString *const DVB_BOARDVIEWCONTROLLER_IDENTIFIER = @"DVBBoardViewController";
NSString *const THREAD_CELL_IDENTIFIER = @"threadCell";
NSString *const POST_CELL_IDENTIFIER = @"postCell";

// Placeholders
NSString *const PLACEHOLDER_COMMENT_FIELD = @"Комментарий";
