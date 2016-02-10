/* Copyright (c) 2013, Felix Paul Kühne and VideoLAN
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, 
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE. */

#import "VDLPlaybackViewController.h"
#import <AVFoundation/AVFoundation.h>

#import <MobileVLCKit/MobileVLCKit.h>

#import "DVBCommon.h"

@interface VDLPlaybackViewController () <UIGestureRecognizerDelegate, VLCMediaPlayerDelegate>
{
    VLCMediaPlayer *_mediaplayer;
    BOOL _setPosition;
    BOOL _displayRemainingTime;
    NSURL *_url;
}

@property (nonatomic, weak) IBOutlet UIView *movieView;
@property (nonatomic, weak) IBOutlet UIView *navigationItemView;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, weak) IBOutlet UISlider *positionSlider;
@property (nonatomic, strong) UIBarButtonItem *timeDisplay;

@property (nonatomic, weak) IBOutlet UIButton *playPauseButton;

@property (nonatomic, assign) BOOL controlsHidden;

@end

@implementation VDLPlaybackViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    _controlsHidden = false;

    _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closePlayback:)];
    _doneButton.title = NSLS(@"BUTTON_CLOSE");

    _timeDisplay = [[UIBarButtonItem alloc] init];
    _timeDisplay.target = self;
    _timeDisplay.action = @selector(toggleTimeDisplay:);
    _timeDisplay.title = @"--:--";

    [_playPauseButton setTitle:@"" forState:UIControlStateNormal];

    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    self.navigationItem.titleView = _navigationItemView;
    self.navigationItem.leftBarButtonItem = _doneButton;
    self.navigationItem.rightBarButtonItem = _timeDisplay;

    UITapGestureRecognizer *tapOnVideoRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControlsVisible)];
    tapOnVideoRecognizer.delegate = self;
    [_movieView addGestureRecognizer:tapOnVideoRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    /* setup the media player instance, give it a delegate and something to draw into */
    _mediaplayer = [[VLCMediaPlayer alloc] init];
    _mediaplayer.delegate = self;
    _mediaplayer.drawable = self.movieView;

    /* listen for notifications from the player */
    [_mediaplayer addObserver:self forKeyPath:@"time" options:0 context:nil];
    [_mediaplayer addObserver:self forKeyPath:@"remainingTime" options:0 context:nil];

    /* create a media object and give it to the player */
    _mediaplayer.media = [VLCMedia mediaWithURL:_url];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_mediaplayer play];

    // Fixing ugly broken pictures of webm's...
    double delayInSecondsPause = 1;
    dispatch_time_t popTimePause = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecondsPause * NSEC_PER_SEC)); // 1
    dispatch_after(popTimePause, dispatch_get_main_queue(), ^(void){
        [_mediaplayer pause];
    });

    double delayInSeconds = 4;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)); // 1
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!_mediaplayer.isPlaying) {
            [_mediaplayer shortJumpBackward];
            [_mediaplayer play];
        }
    });
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (_mediaplayer) {
        @try {
            [_mediaplayer removeObserver:self forKeyPath:@"time"];
            [_mediaplayer removeObserver:self forKeyPath:@"remainingTime"];
        }
        @catch (NSException *exception) {
            NSLog(@"we weren't an observer yet");
        }

        if (_mediaplayer.media)
            [_mediaplayer stop];

        if (_mediaplayer)
            _mediaplayer = nil;
    }

    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)playMediaFromURL:(NSURL*)theURL
{
    _url = theURL;
}

- (IBAction)playandPause:(id)sender
{
    if (_mediaplayer.isPlaying) {
        [_mediaplayer pause];
    } else {
        [_mediaplayer play];
    }
}

- (IBAction)closeAfterEnd:(id)sender
{
    if (!_mediaplayer.isPlaying) {
        [self closePlayback:sender];
    }
}

- (IBAction)closePlayback:(id)sender
{
    [_mediaplayer stop];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)positionSliderAction:(UISlider *)sender
{
    /* we need to limit the number of events sent by the slider, since otherwise, the user
     * wouldn't see the I-frames when seeking on current mobile devices. This isn't a problem
     * within the Simulator, but especially on older ARMv7 devices, it's clearly noticeable. */
    [self performSelector:@selector(_setPositionForReal) withObject:nil afterDelay:0.3];
    _setPosition = NO;
}

- (void)_setPositionForReal
{
    if (!_setPosition) {
        _mediaplayer.position = _positionSlider.value;
        _setPosition = YES;
    }
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    VLCMediaPlayerState currentState = _mediaplayer.state;

    /* distruct view controller on error */
    if (currentState == VLCMediaPlayerStateError)
        [self performSelector:@selector(closeAfterEnd:) withObject:nil afterDelay:2.];

    /* or if playback ended */
    if (currentState == VLCMediaPlayerStateEnded || currentState == VLCMediaPlayerStateStopped)
        [self performSelector:@selector(closeAfterEnd:) withObject:nil afterDelay:2.];

    UIImage *playButtonImage = [UIImage imageNamed:[_mediaplayer isPlaying]? @"PlayerPause" : @"PlayerPlay"];
    [_playPauseButton setBackgroundImage:playButtonImage forState:UIControlStateNormal];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    self.positionSlider.value = [_mediaplayer position];

    [UIView performWithoutAnimation:^{
        if (_displayRemainingTime) {
            _timeDisplay.title = [[_mediaplayer remainingTime] stringValue];
        } else {
            _timeDisplay.title = [[_mediaplayer time] stringValue];
        }
    }];
}

- (IBAction)toggleTimeDisplay:(id)sender
{
    _displayRemainingTime = !_displayRemainingTime;
}

- (void)toggleControlsVisible
{
    _controlsHidden = !_controlsHidden;
    _playPauseButton.hidden = _controlsHidden;
    self.navigationController.navigationBarHidden = _controlsHidden;
    [[UIApplication sharedApplication] setStatusBarHidden:_controlsHidden withAnimation:UIStatusBarAnimationFade];
}

@end
