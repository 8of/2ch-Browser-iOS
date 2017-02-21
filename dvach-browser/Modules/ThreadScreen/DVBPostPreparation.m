//
//  DVBPostPreparation.m
//  dvach-browser
//
//  Created by Andy on 19/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//
#import <UIKit/UIKit.h>

#import "DVBConstants.h"
#import "UrlNinja.h"
#import "DVBPostPreparation.h"
#import "NSString+HTML.h"

@interface DVBPostPreparation ()

@property (nonatomic, strong) NSMutableArray *repliesToPrivate;
// need to know to generate replies
@property (nonatomic, strong) NSString *boardId;
// need to know to generate replies
@property (nonatomic, strong) NSString *threadId;

@property (nonatomic, strong) UIFontDescriptor *bodyFontDescriptor;

@end

@implementation DVBPostPreparation

- (instancetype)init {
    @throw [NSException exceptionWithName:@"Not enough params" reason:@"Use +[DVBPostPreparation initWithBoardId: andThreadId: instead]" userInfo:nil];
    
    return nil;
}

- (instancetype)initWithBoardId:(NSString *)boardId andThreadId:(NSString *)threadId {
    self = [super init];
    
    if (self) {
        _boardId = boardId;
        _threadId = threadId;

        _bodyFontDescriptor= [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleSubheadline];
    }
    
    return self;
}

- (NSArray *)repliesToArrayForPost {
    if (_repliesToPrivate) {
        return _repliesToPrivate;
    }
    
    return [NSArray array];
}

- (NSAttributedString *)commentWithMarkdownWithComments:(NSString *)comment
{
    CGFloat bodyFontSize = [_bodyFontDescriptor pointSize];
    
    // чистка исходника и посильная замена хтмл-литералов
    comment = [comment stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    //comment = [comment stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    comment = [comment stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"];
    comment = [comment stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
    comment = [comment stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    comment = [comment stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
    comment = [comment stringByReplacingOccurrencesOfString:@"&#44;" withString:@","];
    comment = [comment stringByReplacingOccurrencesOfString:@"&#47;" withString:@"/"];
    comment = [comment stringByReplacingOccurrencesOfString:@"&#92;" withString:@"\\"];
    
    NSRange range = NSMakeRange(0, comment.length);
    
    NSMutableAttributedString *maComment = [[NSMutableAttributedString alloc]initWithString:comment];
    [maComment addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:bodyFontSize] range:range];
    
    NSMutableParagraphStyle *commentStyle = [[NSMutableParagraphStyle alloc]init];

    [maComment addAttribute:NSParagraphStyleAttributeName value:commentStyle range:range];

    // dark theme
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        [maComment addAttribute:NSForegroundColorAttributeName value:CELL_TEXT_COLOR range:range];
    }
    
    // em
    UIFont *emFont = [UIFont fontWithName:@"HelveticaNeue-Italic" size:bodyFontSize];
    NSMutableArray *emRangeArray = [NSMutableArray array];
    NSRegularExpression *em = [[NSRegularExpression alloc]initWithPattern:@"<em[^>]*>(.*?)</em>" options:0 error:nil];
    [em enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSFontAttributeName value:emFont range:result.range];
        NSValue *value = [NSValue valueWithRange:result.range];
        [emRangeArray addObject:value];
    }];
    
    // strong
    UIFont *strongFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:bodyFontSize];
    NSMutableArray *strongRangeArray = [NSMutableArray array];
    NSRegularExpression *strong = [[NSRegularExpression alloc]initWithPattern:@"<strong[^>]*>(.*?)</strong>" options:0 error:nil];
    [strong enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSFontAttributeName value:strongFont range:result.range];
        NSValue *value = [NSValue valueWithRange:result.range];
        [strongRangeArray addObject:value];
    }];
    
    // emstrong
    UIFont *emStrongFont = [UIFont fontWithName:@"HelveticaNeue-BoldItalic" size:bodyFontSize];
    for (NSValue *emRangeValue in emRangeArray) {
        //value to range
        NSRange emRange = [emRangeValue rangeValue];
        for (NSValue *strongRangeValue in strongRangeArray) {
            NSRange strongRange = [strongRangeValue rangeValue];
            NSRange emStrongRange = NSIntersectionRange(emRange, strongRange);
            if (emStrongRange.length != 0) {
                [maComment addAttribute:NSFontAttributeName value:emStrongFont range:emStrongRange];
            }
        }
    }

    // underline
    NSRegularExpression *underline = [[NSRegularExpression alloc]initWithPattern:@"<span class=\"u\">(.*?)</span>" options:0 error:nil];
    [underline enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:result.range];
    }];
    
    // strike
    //не будет работать с tttattributedlabel, нужно переделывать ссылки и все такое
    NSRegularExpression *strike = [[NSRegularExpression alloc]initWithPattern:@"<span class=\"s\">(.*?)</span>" options:0 error:nil];
    [strike enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:result.range];
    }];

    // spoiler
    UIColor *spoilerColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        spoilerColor = CELL_TEXT_SPOILER_COLOR;
    }
    NSRegularExpression *spoiler = [[NSRegularExpression alloc]initWithPattern:@"<span class=\"spoiler\">(.*?)</span>" options:0 error:nil];
    [spoiler enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSForegroundColorAttributeName value:spoilerColor range:result.range];
    }];

    // quote
    UIColor *quoteColor = [UIColor colorWithRed:(17/255.0) green:(139/255.0) blue:(116/255.0) alpha:1.0];
    NSRegularExpression *quote = [[NSRegularExpression alloc]initWithPattern:@"<span class=\"unkfunc\">(.*?)</span>" options:0 error:nil];
    [quote enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSForegroundColorAttributeName value:quoteColor range:result.range];
    }];

    // link
    UIColor *linkColor = [UIColor colorWithRed:(255/255.0) green:(102/255.0) blue:(0/255.0) alpha:1.0];
    NSRegularExpression *link = [[NSRegularExpression alloc]initWithPattern:@"<a[^>]*>(.*?)</a>" options:0 error:nil];
    NSRegularExpression *linkLink = [[NSRegularExpression alloc]initWithPattern:@"href=\"(.*?)\"" options:0 error:nil];
    NSRegularExpression *linkLinkTwo = [[NSRegularExpression alloc]initWithPattern:@"href='(.*?)'" options:0 error:nil];

    // prepare repliesTo array
    _repliesToPrivate = [NSMutableArray array];

    if ((!_threadId)||(!_boardId)) {
        @throw [NSException exceptionWithName:@"Not enough params" reason:@"Specify threadId and boardId params please" userInfo:nil];
    }

    [link enumerateMatchesInString:comment
                           options:0
                             range:range
                        usingBlock:^(NSTextCheckingResult *result, __unused NSMatchingFlags flags, __unused BOOL *stop)
    {
        NSString *fullLink = [comment substringWithRange:result.range];
        NSTextCheckingResult *linkLinkResult = [linkLink firstMatchInString:fullLink options:0 range:NSMakeRange(0, fullLink.length)];
        NSTextCheckingResult *linkLinkTwoResult = [linkLinkTwo firstMatchInString:fullLink options:0 range:NSMakeRange(0, fullLink.length)];

        NSRange urlRange = NSMakeRange(0, 0);

        if (linkLinkResult.numberOfRanges != 0) {
            urlRange = NSMakeRange(linkLinkResult.range.location+6, linkLinkResult.range.length-7);
        } else if (linkLinkResult.numberOfRanges != 0) {
            urlRange = NSMakeRange(linkLinkTwoResult.range.location+6, linkLinkTwoResult.range.length-7);
        }

        if (urlRange.length != 0) {
            NSString *urlString = [fullLink substringWithRange:urlRange];
            urlString = [urlString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
            NSURL *url = [[NSURL alloc]initWithString:urlString];
            if (url) {
                UrlNinja *un = [UrlNinja unWithUrl:url];
                
                 if ([un.boardId isEqualToString:_boardId] && [un.threadId isEqualToString:_threadId] && un.type == boardThreadPostLink) {
                     if (![_repliesToPrivate containsObject:un.postId]) {
                         [_repliesToPrivate addObject:un.postId];
                     }
                 }
                
                [maComment addAttribute:NSLinkAttributeName value:url range:result.range];
                [maComment addAttribute:NSForegroundColorAttributeName value:linkColor range:result.range];
                [maComment addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleNone] range:result.range];
            }
        }
    }];
    
    // находим все теги и сохраняем в массив
    NSMutableArray *tagArray = [NSMutableArray array];
    NSRegularExpression *tag = [[NSRegularExpression alloc]initWithPattern:@"<[^>]*>" options:0 error:nil];
    [tag enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSValue *value = [NSValue valueWithRange:result.range];
        [tagArray addObject:value];
    }];
    
    // вырезательный цикл
    int shift = 0;
    for (NSValue *rangeValue in tagArray) {
        NSRange cutRange = [rangeValue rangeValue];
        cutRange.location -= shift;
        [maComment deleteCharactersInRange:cutRange];
        shift += cutRange.length;
    }
    
    // чистим переводы строк в начале и конце
    NSRegularExpression *whitespaceStart = [[NSRegularExpression alloc]initWithPattern:@"^\\s\\s*" options:0 error:nil];
    NSTextCheckingResult *wsResult = [whitespaceStart firstMatchInString:[maComment string] options:0 range:NSMakeRange(0, [maComment length])];
    [maComment deleteCharactersInRange:wsResult.range];
    
    NSRegularExpression *whitespaceEnd = [[NSRegularExpression alloc]initWithPattern:@"\\s\\s*$" options:0 error:nil];
    NSTextCheckingResult *weResult = [whitespaceEnd firstMatchInString:[maComment string] options:0 range:NSMakeRange(0, [maComment length])];
    [maComment deleteCharactersInRange:weResult.range];
    
    // и пробелы в начале каждой строки
    NSMutableArray *whitespaceLineStartArray = [NSMutableArray array];
    NSRegularExpression *whitespaceLineStart = [[NSRegularExpression alloc]initWithPattern:@"^[\\t\\f\\p{Z}]+" options:NSRegularExpressionAnchorsMatchLines error:nil];
    [whitespaceLineStart enumerateMatchesInString:[maComment string] options:0 range:NSMakeRange(0, [maComment length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSValue *value = [NSValue valueWithRange:result.range];
        [whitespaceLineStartArray addObject:value];
    }];
    
    int whitespaceLineStartShift = 0;
    for (NSValue *rangeValue in whitespaceLineStartArray) {
        NSRange cutRange = [rangeValue rangeValue];
        cutRange.location -= whitespaceLineStartShift;
        [maComment deleteCharactersInRange:cutRange];
        whitespaceLineStartShift += cutRange.length;
    }
    
    // и двойные переводы
    NSMutableArray *whitespaceDoubleArray = [NSMutableArray array];
    NSRegularExpression *whitespaceDouble = [[NSRegularExpression alloc]initWithPattern:@"[\\n\\r]{3,}" options:0 error:nil];
    [whitespaceDouble enumerateMatchesInString:[maComment string] options:0 range:NSMakeRange(0, [maComment length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSValue *value = [NSValue valueWithRange:result.range];
        [whitespaceDoubleArray addObject:value];
    }];
    
    int whitespaceDoubleShift = 0;
    for (NSValue *rangeValue in whitespaceDoubleArray) {
        NSRange cutRange = [rangeValue rangeValue];
        cutRange.location -= whitespaceDoubleShift;
        [maComment deleteCharactersInRange:cutRange];
        [maComment insertAttributedString:[[NSAttributedString alloc]initWithString:@"\n\n" attributes:nil] atIndex:cutRange.location];
        whitespaceDoubleShift += cutRange.length - 2;
    }
    
    // Заменить хтмл-литералы на нормальные символы (раньше этого делать нельзя, сломается парсинг).
    [[maComment mutableString] replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    [[maComment mutableString] replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    [[maComment mutableString] replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    [[maComment mutableString] replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    
    return maComment;
}

- (NSString *)cleanPosterNameWithHtmlPosterName:(NSString *)name {
    NSString *plainTextName = [name stringByConvertingHTMLToPlainText];
    
    return plainTextName;
}

- (BOOL)isPostContaintSageWithEmail:(NSString *)email {
    NSString *sageStringToLookFor = @"sage";
    if ([email rangeOfString:sageStringToLookFor options:NSCaseInsensitiveSearch].location != NSNotFound) {
        return YES;
    }
    return NO;
}

@end
