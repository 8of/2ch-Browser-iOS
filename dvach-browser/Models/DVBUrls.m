//
//  DVBUrls.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 30/09/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBUrls.h"

@implementation DVBUrls

static NSString *_base;
static NSString *_baseWithoutScheme;
static NSString *_baseWithoutSchemeForUrlNinja;
static NSString *_baseWithoutSchemeForUrlNinjaHk = @"2ch.hk";
static NSString *_reportThread;
static NSString *_boardsList;
static NSString *_getUsercode;
static NSString *_checkReviewStatus = @"http://8of.org/2ch/status.json";

/// https://2ch.hk/
+ (NSString *)base
{
    if (_base == nil) {
        _base = [NSString stringWithFormat:@"https://%@", [self domain]];
    }
    return _base;
}

/// 2ch.hk/
+ (NSString *)baseWithoutScheme
{
    if (_baseWithoutScheme == nil) {
        _baseWithoutScheme = [NSString stringWithFormat:@"%@/", [self domain]];
    }
    return _baseWithoutScheme;
}

/// 2ch.hk
+ (NSString *)baseWithoutSchemeForUrlNinja
{
    if (_baseWithoutSchemeForUrlNinja == nil) {
        _baseWithoutSchemeForUrlNinja = [self domain];
    }
    return _baseWithoutSchemeForUrlNinja;
}

/// Always 2ch.hk
+ (NSString *)baseWithoutSchemeForUrlNinjaHk
{
    return _baseWithoutSchemeForUrlNinjaHk;
}

/// https://2ch.hk/makaba/makaba.fcgi
+ (NSString *)reportThread
{
    if (_reportThread == nil) {
        _reportThread = [NSString stringWithFormat:@"https://%@/makaba/makaba.fcgi", [self domain]];
    }
    return _reportThread;
}

/// https://2ch.hk/makaba/mobile.fcgi?task=get_boards
+ (NSString *)boardsList
{
    if (_boardsList == nil) {
        _boardsList = [NSString stringWithFormat:@"https://%@/makaba/mobile.fcgi?task=get_boards", [self domain]];
    }
    return _boardsList;
}

/// https://2ch.hk/makaba/makaba.fcgi
+ (NSString *)getUsercode
{
    if (_getUsercode == nil) {
        _getUsercode = [NSString stringWithFormat:@"https://%@/makaba/makaba.fcgi", [self domain]];
    }
    return _getUsercode;
}

/// http://8of.org/2ch/status.json
+ (NSString *)checkReviewStatus
{
    return _checkReviewStatus;
}

+ (void)reset
{
    _base = nil;
    _baseWithoutScheme = nil;
    _baseWithoutSchemeForUrlNinja = nil;
    _reportThread = nil;
    _boardsList = nil;
    _getUsercode = nil;
}

// Private

+ (NSString *)domain
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:SETTING_BASE_DOMAIN];
}

@end
