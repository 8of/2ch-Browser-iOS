//
//  VDLPlaybackViewController.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 01/09/15.
//  Copyright (c) 2016 8of. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

///  WebM player controller
@interface VDLPlaybackViewController : UIViewController

- (void)playMediaFromURL:(NSURL*)theURL;

@end
