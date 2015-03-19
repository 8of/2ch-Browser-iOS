//
//  DVBThreadViewController.m
//  dvach-browser
//
//  Created by Andy on 11/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBThreadViewController.h"
#import "DVBPostObj.h"
#import "DVBPostTableViewCell.h"
#import "NSString+HTML.h"
#import "Reachability.h"
#import "DVBBadPost.h"
#import "DVBBadPostStorage.h"
#import "DVBCreatePostViewController.h"
#import "DVBComment.h"
#import "DVBNetworking.h"
#import "DVBStatus.h"
#import "DVBBrowserViewControllerBuilder.h"
#import "UrlNinja.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define kCommentFontSize        14.0f
#define kCommentLineSpacing     2.0f

static NSString *const POST_CELL_IDENTIFIER = @"postCell";
static NSString *const SEGUE_TO_NEW_POST = @"segueToNewPost";

/**
 *  Too much magic numbers for iOS 7. Need to rewrite somehow.
 */

// default row height
static CGFloat const ROW_DEFAULT_HEIGHT = 81.0f;

// thumbnail width in post row
static CGFloat const THUMBNAIL_WIDTH = 65.f;
//thumbnail contstraints for calculating layout dimentions
static CGFloat const THUMBNAIL_CONSTRAINT_LEFT = 8.0f;
static CGFloat const THUMBNAIL_CONSTRAINT_RIGHT = 8.0f;

// settings for handling long pressure gesture on table cell
static CGFloat const MINIMUM_PRESS_DURATION = 1.2F;
static CGFloat const ALLOWABLE_MOVEMENT = 100.0f;

// settings for comment textView
static CGFloat const CORRECTION_WIDTH_FOR_TEXT_VIEW_CALC = 30.f; // magical number of 30 - to correct width of container while calculating enough size for view to shop comment text
/**
 *  Correction from top contstr = 8, bottom contstraint = 8 and border = 1 8+8+1 = 17
 */
static CGFloat const CORRECTION_HEIGHT_FOR_TEXT_VIEW_CALC = 17.0f;

// static CGFloat const TEXTVIEW_INSET = 8;

@protocol sendDataProtocol <NSObject>

- (void)sendDataToBoard:(NSUInteger)deletedObjectIndex;

@end

@interface DVBThreadViewController () <UIActionSheetDelegate, DVBCreatePostViewControllerDelegate>

// for recofnizing long press on post row
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureOnPicture;

// array of posts inside this thread
@property (nonatomic, strong) NSMutableArray *postsArray;

// array of all post thumb images in thread
@property (nonatomic, strong) NSMutableArray *thumbImagesArray;
// array of all post full images in thread
@property (nonatomic, strong) NSMutableArray *fullImagesArray;
@property (nonatomic, strong) DVBPostTableViewCell *prototypeCell;

// action sheet for displaying bad posts flaggind (and maybe somethig more later)
@property (nonatomic, strong) UIActionSheet *postLongPressSheet;
@property (nonatomic, strong) NSString *flaggedPostNum;
@property (nonatomic, assign) NSUInteger selectedWithLongPressSection;

@property (nonatomic, assign) NSUInteger updatedTimes;

// storage for bad posts, marked on this specific device
@property (nonatomic, strong) DVBBadPostStorage *badPostsStorage;

// for marking if OP message already glagged or not (tech prop)
@property (nonatomic, assign) BOOL opAlreadyDeleted;

// test array for new photo browser
@property (nonatomic, strong) NSMutableArray *photos;

// flagging
@property (weak, nonatomic) IBOutlet UIBarButtonItem *flagButton;

@end

@implementation DVBThreadViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prepareViewController];
    [self reloadThread];
}

- (void)prepareViewController
{
    [self.navigationController setToolbarHidden:NO animated:NO];
    /**
     *  Set view controller title depending on...
     */
    self.title = [self getSubjectOrNumWithSubject:_threadSubject
                                     andThreadNum:_threadNum];
    [self addGestureRecognisers];
    
    /**
     Handling bad posts on this device
     */
    _badPostsStorage = [[DVBBadPostStorage alloc] init];
    NSString *path = [_badPostsStorage badPostsArchivePath];
    
    _badPostsStorage.badPostsArray = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    if (!_badPostsStorage.badPostsArray)
    {
        _badPostsStorage.badPostsArray = [[NSMutableArray alloc] initWithObjects:nil];
    }
    
    _opAlreadyDeleted = NO;
}

#pragma mark - Set titles and gestures

- (NSString *)getSubjectOrNumWithSubject:(NSString *)subject
                            andThreadNum:(NSString *)num
{
    /**
     *  If thread Subject is empty - return OP post number
     */
    BOOL isSubjectEmpty = [subject isEqualToString:@""];
    if (isSubjectEmpty)
    {
        return num;
    }
    
    return subject;
}

- (void)addGestureRecognisers
{
    // setting for long pressure gesture
    _longPressGestureOnPicture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestures:)];
    _longPressGestureOnPicture.minimumPressDuration = MINIMUM_PRESS_DURATION;
    _longPressGestureOnPicture.allowableMovement = ALLOWABLE_MOVEMENT;
    
    [self.tableView addGestureRecognizer:_longPressGestureOnPicture];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_postsArray count];
}
/**
 *  Set every section title depending on post SUBJECT or NUMBER
 */
- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section
{
    DVBPostObj *postTmpObj = _postsArray[section];
    NSString *subject = postTmpObj.subject;
    
    subject = [self getSubjectOrNumWithSubject:subject
                                  andThreadNum:postTmpObj.num];
    
    // we increase number by one because sections start count from 0 and post counts on 2ch commonly start with 1
    NSInteger postNumToShow = section + 1;
    
    NSString *sectionTitle = [[NSString alloc] initWithFormat:@"#%ld %@", (long)postNumToShow, subject];
    
    return sectionTitle;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    // only one row inside every section for now
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBPostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:POST_CELL_IDENTIFIER
                                                                 forIndexPath:indexPath];
    [self configureCell:cell
      forRowAtIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // do not calculate anything if iOS ver > 8.0
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
    {
// #warning need to uncomment this for smooth iOS 8 experience, but now cells not resizes themself properly so let it be commented for now
     //   return UITableViewAutomaticDimension;
    }
    // I am using a helper method here to get the text at a given cell.
    NSAttributedString *text = [self getTextAtIndex:indexPath];
    
    // Getting the width/height needed by the dynamic text view.

    CGSize viewSize = self.tableView.bounds.size;
    NSInteger viewWidth = viewSize.width;
    
    /**
     *  Set default difference (if we hve image in the cell).
     */
    CGFloat widthDifferenceBecauseOfImage = THUMBNAIL_WIDTH + THUMBNAIL_CONSTRAINT_LEFT + THUMBNAIL_CONSTRAINT_RIGHT;
    
    /**
     *  Determine if we really have image in the cell.
     */
    DVBPostObj *postObj = _postsArray[indexPath.section];
    NSString *thumbPath = postObj.thumbPath;
    
    /**
     *  If not - then set the difference to 0.
     */
    if ([thumbPath isEqualToString:@""])
    {
        widthDifferenceBecauseOfImage = 0;
    }
    
    // we decrease window width value by taking off elements and contraints values
    CGFloat textViewWidth = viewWidth - widthDifferenceBecauseOfImage;
    
    // correcting width by magic number
    CGFloat width = textViewWidth - CORRECTION_WIDTH_FOR_TEXT_VIEW_CALC;
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    CGSize size = [self frameForText:text sizeWithFont:font constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)];
    
    // Return the size of the current row.
    // 81 is the minimum height! Update accordingly
    CGFloat heightToReturn = size.height;
    
    CGFloat heightForReturnWithCorrectionAndCeilf = ceilf(heightToReturn + CORRECTION_HEIGHT_FOR_TEXT_VIEW_CALC);
    
    if (heightToReturn < ROW_DEFAULT_HEIGHT)
    {
        if ([thumbPath isEqualToString:@""])
        {
            return heightForReturnWithCorrectionAndCeilf;
        }
        
        return ROW_DEFAULT_HEIGHT;
    }
    
    return heightForReturnWithCorrectionAndCeilf;
}

/**
 *  For more smooth and fast user expierence (iOS 8).
 */
- (CGFloat)tableView:(UITableView *)tableView
estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBPostObj *selectedPost = _postsArray[indexPath.section];
    NSString *thumbUrl = selectedPost.thumbPath;
    
    // Check if cell have real image or just placeholder.
    // We handle tap on cell to fire gallery, not only tap on image itself.
    if (![thumbUrl isEqualToString:@""])
    {
        [self handleTapOnImageViewWithIndexPath:indexPath];
    }
    
}

#pragma mark - Cell configuration and calculation

- (void)configureCell:(UITableViewCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[DVBPostTableViewCell class]])
    {
        DVBPostTableViewCell *confCell = (DVBPostTableViewCell *)cell;
        
        DVBPostObj *postTmpObj = _postsArray[indexPath.section];
        
        // NSString *stringForTextView = [postTmpObj.comment stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        /**
         *  This is the second part of the fix for fixing broke links in comments.
         */
        // stringForTextView = [NSString stringWithFormat:@"%@%@", @"\u200B", stringForTextView];
        
        NSString *thumbUrlString = postTmpObj.thumbPath;
        
        [confCell prepareCellWithCommentText:postTmpObj.comment
                       andPostThumbUrlString:thumbUrlString];

    }
}
/**
 *  Think of this as some utility function that given text, calculates how much space we need to fit that text. Calculation for texView height.
 */
-(CGSize)frameForText:(NSAttributedString *)text
         sizeWithFont:(UIFont *)font
    constrainedToSize:(CGSize)size
{
    /*
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          font, NSFontAttributeName,
                                          nil];
     */
    CGRect frame = [text boundingRectWithSize:size options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading) context:nil];
    /*
    CGRect frame = [text boundingRectWithSize:size
                                      options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                   attributes:attributesDictionary
                                      context:nil];
    */
    /**
     *  This contains both height and width, but we really care about height.
     */
    return frame.size;
}

/**
 *  Think of this as a source for the text to be rendered in the text view.
 *  I used a dictionary to map indexPath to some dynamically fetched text.
 */
- (NSAttributedString *)getTextAtIndex:(NSIndexPath *)indexPath
{
    
    NSUInteger tmpIndex = indexPath.section;
    DVBPostObj *tmpObj =  _postsArray[tmpIndex];
    NSAttributedString *tmpComment = tmpObj.comment;
    
    return tmpComment;
}

#pragma mark - Data management and processing

/**
 *  Get data from 2ch server
 *
 *  @param board      <#board description#>
 *  @param threadNum  <#threadNum description#>
 *  @param completion <#completion description#>
 */
- (void)getPostsWithBoard:(NSString *)board
                andThread:(NSString *)threadNum
            andCompletion:(void (^)(NSArray *))completion
{
    
    DVBNetworking *networking = [[DVBNetworking alloc] init];
    
    [networking getPostsWithBoard:board
                        andThread:threadNum
                    andCompletion:^(NSDictionary *completion2)
    {
        NSMutableArray *postsFullMutArray = [NSMutableArray array];
        
        _thumbImagesArray = [[NSMutableArray alloc] init];
        _fullImagesArray = [[NSMutableArray alloc] init];
        
        // building URL for getting JSON-thread-answer from mutiple strings
        // there is better one-line solution for this - need to use stringWithFormat
        // rewrite in future!
        
        
        
        
             NSMutableDictionary *resultDict = [completion2 mutableCopy];
             
             NSArray *threadsDict = [resultDict objectForKey:@"threads"];
             NSDictionary *postsArray = [threadsDict objectAtIndex:0];
             NSArray *posts2Array = [postsArray objectForKey:@"posts"];
             
             for (id key in posts2Array)
             {
                 NSString *num = [[key objectForKey:@"num"] stringValue];
                 
                 // server gives me number but I need string
                 NSString *tmpNumForPredicate = [[key objectForKey:@"num"] stringValue];
                 
                 //searching for bad posts
                 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.num contains[cd] %@", tmpNumForPredicate];
                 NSArray *filtered = [self.badPostsStorage.badPostsArray filteredArrayUsingPredicate:predicate];
                 
                 if ([filtered count] > 0)
                 {
                     continue;
                 }
                 
                 NSString *comment = [key objectForKey:@"comment"];
                 NSString *subject = [key objectForKey:@"subject"];
                 
                 // comment = [self makeBody:comment];
                 NSAttributedString *comment2 = [self makeBody:comment];
                 /*
                 // replacing regular BR with our own strange NEWLINE "tag" - so nxt method wont entirely wipe BreakLine functionality
                 comment = [comment stringByReplacingOccurrencesOfString:@"<br>"
                                                              withString:@":::newline:::"];
                 
                 // deleteing HTML markup from comment text
                 comment = [comment stringByConvertingHTMLToPlainText];
                 
                 // replacing our weird NEWLINE tag with regular cocoa breakline symbol
                 comment = [comment stringByReplacingOccurrencesOfString:@":::newline:::"
                                                              withString:@"\n"];
                 */
                 
                 NSDictionary *files = [[key objectForKey:@"files"] objectAtIndex:0];
                 
                 NSMutableString *thumbPathMut;
                 NSMutableString *picPathMut;
                 
                 if (files != nil)
                 {
                     
                     // check webm or not
                     NSString *fullFileName = [files objectForKey:@"path"];
                     if ([fullFileName rangeOfString:@".webm" options:NSCaseInsensitiveSearch].location != NSNotFound)
                     {
                         
                         // if contains .webm
                         thumbPathMut = [[NSMutableString alloc] initWithString:@""];
                         picPathMut = [[NSMutableString alloc] initWithString:@""];
                         
                     }
                     else
                     {
                         
                         // if not contains .webm
                         
                         // rewrite in future
                         NSMutableString *fullThumbPath = [[NSMutableString alloc] initWithString:DVACH_BASE_URL];
                         [fullThumbPath appendString:self.boardCode];
                         [fullThumbPath appendString:@"/"];
                         [fullThumbPath appendString:[files objectForKey:@"thumbnail"]];
                         thumbPathMut = fullThumbPath;
                         fullThumbPath = nil;
                         
                         // rewrite in future
                         NSMutableString *fullPicPath = [[NSMutableString alloc] initWithString:DVACH_BASE_URL];
                         [fullPicPath appendString:_boardCode];
                         [fullPicPath appendString:@"/"];
                         [fullPicPath appendString:[files objectForKey:@"path"]];
                         picPathMut = fullPicPath;
                         fullPicPath = nil;
                         
                         [_thumbImagesArray addObject:thumbPathMut];
                         [_fullImagesArray addObject:picPathMut];
                         
                     }
                     
                 }
                 else
                 {
                     // if there are no files - make blank file paths
                     thumbPathMut = [[NSMutableString alloc] initWithString:@""];
                     picPathMut = [[NSMutableString alloc] initWithString:@""];
                 }
                 NSString *thumbPath = thumbPathMut;
                 NSString *picPath = picPathMut;
                 
                 DVBPostObj *postObj = [[DVBPostObj alloc] initWithNum:num subject:subject comment:comment2 path:picPath thumbPath:thumbPath];
                 [postsFullMutArray addObject:postObj];
                 postObj = nil;
             }
             
             NSArray *resultArr = [[NSArray alloc] initWithArray:postsFullMutArray];
             
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             
             completion(resultArr);
        
    }];

}

- (NSAttributedString *) makeBody:(NSString *)comment {
    
    //чистка исходника и посильная замена хтмл-литералов
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
    [maComment addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:kCommentFontSize] range:range];
    
    NSMutableParagraphStyle *commentStyle = [[NSMutableParagraphStyle alloc]init];
    //    commentStyle.lineSpacing = kCommentLineSpacing;
    [maComment addAttribute:NSParagraphStyleAttributeName value:commentStyle range:range];
    
    //em
    UIFont *emFont = [UIFont fontWithName:@"HelveticaNeue-Italic" size:kCommentFontSize];
    NSMutableArray *emRangeArray = [NSMutableArray array];
    NSRegularExpression *em = [[NSRegularExpression alloc]initWithPattern:@"<em[^>]*>(.*?)</em>" options:0 error:nil];
    [em enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSFontAttributeName value:emFont range:result.range];
        NSValue *value = [NSValue valueWithRange:result.range];
        [emRangeArray addObject:value];
    }];
    
    //strong
    UIFont *strongFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:kCommentFontSize];
    NSMutableArray *strongRangeArray = [NSMutableArray array];
    NSRegularExpression *strong = [[NSRegularExpression alloc]initWithPattern:@"<strong[^>]*>(.*?)</strong>" options:0 error:nil];
    [strong enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSFontAttributeName value:strongFont range:result.range];
        NSValue *value = [NSValue valueWithRange:result.range];
        [strongRangeArray addObject:value];
    }];
    
    //emstrong
    UIFont *emStrongFont = [UIFont fontWithName:@"HelveticaNeue-BoldItalic" size:kCommentFontSize];
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
    
    //strike
    //не будет работать с tttattributedlabel, нужно переделывать ссылки и все такое
    NSRegularExpression *strike = [[NSRegularExpression alloc]initWithPattern:@"<span class=\"s\">(.*?)</span>" options:0 error:nil];
    [strike enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:result.range];
    }];
    
    //spoiler
    UIColor *spoilerColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    NSRegularExpression *spoiler = [[NSRegularExpression alloc]initWithPattern:@"<span class=\"spoiler\">(.*?)</span>" options:0 error:nil];
    [spoiler enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSForegroundColorAttributeName value:spoilerColor range:result.range];
    }];
    
    //quote
    UIColor *quoteColor = [UIColor colorWithRed:(17/255.0) green:(139/255.0) blue:(116/255.0) alpha:1.0];
    NSRegularExpression *quote = [[NSRegularExpression alloc]initWithPattern:@"<span class=\"unkfunc\">(.*?)</span>" options:0 error:nil];
    [quote enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSForegroundColorAttributeName value:quoteColor range:result.range];
    }];
    
    //link
    UIColor *linkColor = [UIColor colorWithRed:(255/255.0) green:(102/255.0) blue:(0/255.0) alpha:1.0];
    NSRegularExpression *link = [[NSRegularExpression alloc]initWithPattern:@"<a[^>]*>(.*?)</a>" options:0 error:nil];
    NSRegularExpression *linkLink = [[NSRegularExpression alloc]initWithPattern:@"href=\"(.*?)\"" options:0 error:nil];
    NSRegularExpression *linkLinkTwo = [[NSRegularExpression alloc]initWithPattern:@"href='(.*?)'" options:0 error:nil];
    
    [link enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, __unused NSMatchingFlags flags, __unused BOOL *stop) {
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
                /*
                if ([un.boardId isEqualToString:self.boardId] && [un.threadId isEqualToString:self.threadId] && un.type == boardThreadPostLink) {
                    if (![self.replyTo containsObject:un.postId]) {
                        [self.replyTo addObject:un.postId];
                    }
                }
                 */
                [maComment addAttribute:NSLinkAttributeName value:url range:result.range];
                [maComment addAttribute:NSForegroundColorAttributeName value:linkColor range:result.range];
                [maComment addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleNone] range:result.range];
            }
        }
    }];
    
    //находим все теги и сохраняем в массив
    NSMutableArray *tagArray = [NSMutableArray array];
    NSRegularExpression *tag = [[NSRegularExpression alloc]initWithPattern:@"<[^>]*>" options:0 error:nil];
    [tag enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSValue *value = [NSValue valueWithRange:result.range];
        [tagArray addObject:value];
    }];
    
    //вырезательный цикл
    int shift = 0;
    for (NSValue *rangeValue in tagArray) {
        NSRange cutRange = [rangeValue rangeValue];
        cutRange.location -= shift;
        [maComment deleteCharactersInRange:cutRange];
        shift += cutRange.length;
    }
    
    //чистим переводы строк в начале и конце
    NSRegularExpression *whitespaceStart = [[NSRegularExpression alloc]initWithPattern:@"^\\s\\s*" options:0 error:nil];
    NSTextCheckingResult *wsResult = [whitespaceStart firstMatchInString:[maComment string] options:0 range:NSMakeRange(0, [maComment length])];
    [maComment deleteCharactersInRange:wsResult.range];
    
    NSRegularExpression *whitespaceEnd = [[NSRegularExpression alloc]initWithPattern:@"\\s\\s*$" options:0 error:nil];
    NSTextCheckingResult *weResult = [whitespaceEnd firstMatchInString:[maComment string] options:0 range:NSMakeRange(0, [maComment length])];
    [maComment deleteCharactersInRange:weResult.range];
    
    //и пробелы в начале каждой строки
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
    
    //и двойные переводы
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
    
    //добавляем заголовок поста, если он есть
    /*
    if (self.subject && ![self.subject isEqualToString:@""]) {
        
        self.subject = [self.subject stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
        self.subject = [self.subject stringByReplacingOccurrencesOfString:@"&#44;" withString:@","];
        
        NSMutableAttributedString *maSubject = [[NSMutableAttributedString alloc]initWithString:[self.subject stringByAppendingString:@"\n"]];
        [maSubject addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0] range:NSMakeRange(0, maSubject.length)];
        [maSubject addAttribute:NSParagraphStyleAttributeName value:commentStyle range:NSMakeRange(0, maSubject.length)];
        
        [maComment insertAttributedString:maSubject atIndex:0];
    }
     */
    
    //заменить хтмл-литералы на нормальные символы (раньше этого делать нельзя, сломается парсинг)
    [[maComment mutableString] replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    [[maComment mutableString] replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    [[maComment mutableString] replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    [[maComment mutableString] replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    
    return maComment;
}

// reload thread by current thread num
- (void)reloadThread {
    [self getPostsWithBoard:_boardCode
                  andThread:_threadNum
              andCompletion:^(NSArray *postsArrayBlock)
    {
        _postsArray = [postsArrayBlock mutableCopy];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

- (void)reloadThreadFromOutside
{
    [self reloadThread];
}

#pragma mark - Actions from Storyboard

- (IBAction)reloadThreadAction:(id)sender
{
    [self reloadThread];
}

- (IBAction)scrollToTop:(id)sender
{
    CGPoint pointToScrollTo = CGPointMake(0, 0 - self.tableView.contentInset.top);
    [self.tableView setContentOffset:pointToScrollTo animated:YES];
}

- (IBAction)scrollToBottom:(id)sender
{
    CGPoint pointToScrollTo = CGPointMake(0, self.tableView.contentSize.height-self.tableView.frame.size.height);
    [self.tableView setContentOffset:pointToScrollTo animated:YES];
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier
                                  sender:(id)sender
{
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([[segue identifier] isEqualToString:SEGUE_TO_NEW_POST])
    {
        DVBCreatePostViewController *createPostViewController = (DVBCreatePostViewController*) [[segue destinationViewController] topViewController];
        
        createPostViewController.threadNum = _threadNum;
        createPostViewController.boardCode = _boardCode;
        createPostViewController.createPostViewControllerDelegate = self;
    }
}

- (void)handleLongPressGestures:(UILongPressGestureRecognizer *)gestureRecognizer
{
    // try to understand on which cell we performed long press gesture
    CGPoint p = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        
        DVBPostObj *postObj = [_postsArray objectAtIndex:indexPath.section];
        
        // setting variable to bad post number (we'll use it soon)
        _flaggedPostNum = postObj.num;
        
        _selectedWithLongPressSection = (NSUInteger)indexPath.section;
        _postLongPressSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                          delegate:self
                                                 cancelButtonTitle:@"Отмена"
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:@"Ответить", @"Открыть в браузере", @"Пожаловаться", nil];
        
        [_postLongPressSheet showInView:self.tableView];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet
didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if (actionSheet == _postLongPressSheet)
    {
        switch (buttonIndex)
        {
                
            case 0:
            {
                // add post answer to comment and make segue
                DVBComment *sharedComment = [DVBComment sharedComment];
                
                NSString *oldCommentText = sharedComment.comment;
                
                DVBPostObj *post = [_postsArray objectAtIndex:self.selectedWithLongPressSection];
                
                NSString *postNum = post.num;
                
                NSString *newStringOfComment = @"";
                
                // first one is for creating blank comment
                if ([oldCommentText isEqualToString:@""])
                {
                    newStringOfComment = [[NSString alloc] initWithFormat:@">>%@\n", postNum];
                }
                
                // second one works when there is some text in comment already
                else
                {
                    newStringOfComment = [[NSString alloc] initWithFormat:@"\n>>%@\n", postNum];
                }

                NSString *commentToSingleton = [[NSString alloc] initWithFormat:@"%@%@", oldCommentText, newStringOfComment];
                
                sharedComment.comment = commentToSingleton;
                
                NSLog(@"%@", sharedComment.comment);
                [self performSegueWithIdentifier:SEGUE_TO_NEW_POST
                                          sender:self];
                break;
            }
                
            case 1:
            {
                // open in browser button
                NSString *urlToOpen = [[NSString alloc] initWithFormat:@"%@%@/res/%@.html", DVACH_BASE_URL, _boardCode, _threadNum];
                NSLog(@"URL: %@", urlToOpen);
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlToOpen]];
                break;
            }
                
            case 2:
            {
                // Flag button
                [self sendPost:_flaggedPostNum andBoard:_boardCode andCompletion:^(BOOL done) {
                    NSLog(@"Post complaint sent.");
                    if (done)
                    {
                        [self deletePostWithIndex:self.selectedWithLongPressSection fromMutableArray:self.postsArray];
                    }
                }];
                break;
            }
            default:
            {
                break;
            }
        }
    }
}

#pragma mark - Bad posts reporting

/**
 *  Function for flag inappropriate content and send it to moderators DB.
 */
- (void) sendPost:(NSString *)postNum
         andBoard:(NSString *)board
    andCompletion:(void (^)(BOOL ))completion
{
    NSString *currentPostNum = postNum;
    NSString *currentBoard = board;
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable)
    {
        NSLog(@"Cannot find internet.");
        BOOL result = NO;
        return completion(result);
    }
    else
    {
        
        // building URL for sendin JSON to my server (for tickets)
        // there is better one-line solution for this - need to use stringWithFormat
        // rewrite in future!
        
        NSMutableString *requestAddress = [[NSMutableString alloc] initWithString:COMPLAINT_URL];
        [requestAddress appendString:@"?postnum="];
        [requestAddress appendString:currentPostNum];
        [requestAddress appendString:@"&board="];
        [requestAddress appendString:currentBoard];
        
        NSURLRequest *activeRequest = [NSURLRequest requestWithURL:
                                       [NSURL URLWithString:requestAddress]];
        
        [NSURLConnection sendAsynchronousRequest:activeRequest
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response,
                                                   NSData *data,
                                                   NSError *connectionError)
         {
             NSError *jsonError;
             
             NSMutableDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:data
                                                                               options:NSJSONReadingAllowFragments
                                                                                 error:&jsonError];
             
             NSString *status = [resultDict objectForKey:@"status"];
             
             BOOL ok = YES;
             
             if (![status isEqualToString:@"1"])
             {
                 completion(NO);
             }
             
             completion(ok);
         }];
    }
}

- (void)deletePostWithIndex:(NSUInteger)index
           fromMutableArray:(NSMutableArray *)array
{
    [array removeObjectAtIndex:index];
    BOOL threadOrNot = NO;
    if ((index == 0)&&(!_opAlreadyDeleted))
    {
        threadOrNot = YES;
        self.opAlreadyDeleted = YES;
    }
    DVBBadPost *tmpBadPost = [[DVBBadPost alloc] initWithNum:_flaggedPostNum
                                                 threadOrNot:threadOrNot];
    [_badPostsStorage.badPostsArray addObject:tmpBadPost];
    BOOL badPostsSavingSuccess = [_badPostsStorage saveChanges];
    if (badPostsSavingSuccess)
    {
        NSLog(@"Bad Posts saved to file");
    }
    else
    {
        NSLog(@"Couldn't save bad posts to file");
    }
    if (index == 0)
    {
        [self.delegate sendDataToBoard:self.threadIndex];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        [self.tableView reloadData];
        [self showAlertAboutReportedPost];
    }
}

- (void)showAlertAboutReportedPost
{
    NSString *complaintSentAlertTitle = NSLocalizedString(@"Жалоба отправлена", @"Заголовок alert'a сообщает о том, что жалоба отправлена.");
    NSString *complaintSentAlertMessage = NSLocalizedString(@"Ваша жалоба посталена в очередь на проверку модератором. Пост был скрыт.", @"Текст alert'a сообщает о том, что жалоба отправлена.");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:complaintSentAlertTitle
                                                        message:complaintSentAlertMessage
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
    [alertView setTag:1];
    [alertView show];
}

- (IBAction)reportButtonAction:(id)sender
{
    /**
     *  Report entire thread (all for mods).
     */
    [self sendPost:_threadNum andBoard:_boardCode andCompletion:^(BOOL done)
    {
        NSLog(@"Post complaint sent.");
        if (done)
        {
            [self deletePostWithIndex:_selectedWithLongPressSection
                     fromMutableArray:_postsArray];
        }
    }];
}

#pragma mark - Photo gallery

// Tap on image method
- (void)handleTapOnImageViewWithIndexPath:(NSIndexPath *)indexPath
{
    [self createAndPushGalleryWithIndexPath:indexPath];
}

- (void)createAndPushGalleryWithIndexPath:(NSIndexPath *)indexPath
{
    DVBBrowserViewControllerBuilder *browser = [[DVBBrowserViewControllerBuilder alloc] initWithDelegate:nil];

    NSUInteger indexForImageShowing = indexPath.section;
    DVBPostObj *postObj = [_postsArray objectAtIndex:indexForImageShowing];
    NSString *path = postObj.path;
    NSUInteger index = [_fullImagesArray indexOfObject:path];

    browser.index = index;
    
    [browser prepareWithIndex:index
          andThumbImagesArray:_thumbImagesArray
           andFullImagesArray:_fullImagesArray];

    // Present
    [self.navigationController pushViewController:browser animated:YES];
}

#pragma mark - DVBCreatePostViewControllerDelegate

-(void)updateThreadAfterPosting
{
    /**
     *  Update thread from network.
     */
    [self reloadThread];
    /**
     *  Scroll thread to bottom. Not working as it should for now.
     */
    CGPoint pointToScrollTo = CGPointMake(0, self.tableView.contentSize.height-self.tableView.frame.size.height);
    [self.tableView setContentOffset:pointToScrollTo animated:YES];
    
    NSLog(@"Table updated after posting.");
}

@end
