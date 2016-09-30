//
//  VDLPlaybackViewController.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 01/09/15.
//  Copyright (c) 2016 8of. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreText/CoreText.h>
#import <MobileVLCKit/MobileVLCKit.h>

#import "DVBCommon.h"
#import "VDLPlaybackViewController.h"

@interface VDLPlaybackViewController () <UIGestureRecognizerDelegate, VLCMediaPlayerDelegate>
{
    VLCMediaPlayer *_mediaplayer;
    BOOL _setPosition;
    NSURL *_url;
}

@property (nonatomic, weak) IBOutlet UIView *movieView;
@property (nonatomic, weak) IBOutlet UIView *navigationItemView;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, weak) IBOutlet UISlider *positionSlider;
@property (nonatomic, strong) UIBarButtonItem *timeDisplay;
@property (nonatomic, assign) BOOL controlsHidden;
@property (nonatomic, strong) UIBarButtonItem *playPauseItem;

@end

@implementation VDLPlaybackViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    _controlsHidden = false;

    _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closePlayback:)];
    _doneButton.title = NSLS(@"BUTTON_CLOSE");

    _timeDisplay = [[UIBarButtonItem alloc] initWithTitle:@" ---:--  " style:UIBarButtonItemStylePlain target:self action:nil];

    // Change font to monospace version
    NSArray *monospacedSetting = @[@{UIFontFeatureTypeIdentifierKey: @(kNumberSpacingType),
                                     UIFontFeatureSelectorIdentifierKey: @(kMonospacedNumbersSelector)}];
    UIFontDescriptor *newDescriptor = [[[UIFont systemFontOfSize:17.0] fontDescriptor] fontDescriptorByAddingAttributes:@{UIFontDescriptorFeatureSettingsAttribute: monospacedSetting}];
    [_timeDisplay setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithDescriptor:newDescriptor size:0], NSFontAttributeName, nil]
                                forState:UIControlStateNormal];

    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    self.navigationItem.titleView = _navigationItemView;
    self.navigationItem.leftBarButtonItem = _doneButton;
    self.navigationItem.rightBarButtonItem = _timeDisplay;

    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    _playPauseItem = [[UIBarButtonItem alloc] initWithImage:[self playButtonImage] style:UIBarButtonItemStylePlain target:self action:@selector(playAndPause:)];

    self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
    [self setToolbarItems:@[flexibleItem, _playPauseItem, flexibleItem] animated:NO];

    UITapGestureRecognizer *tapOnVideoRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControlsVisible)];
    tapOnVideoRecognizer.delegate = self;
    [_movieView addGestureRecognizer:tapOnVideoRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:NO];

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
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
}

- (void)playMediaFromURL:(NSURL*)theURL
{
    _url = theURL;
}

- (UIImage *)playButtonImage
{
    return [UIImage imageNamed:[_mediaplayer isPlaying]? @"PlayerPause" : @"PlayerPlay"];
}

- (void)changeImageFor:(UIBarButtonItem *)item
{
    [item setImage:[self playButtonImage]];
}

#pragma mark - Actions

- (IBAction)playAndPause:(id)sender
{
    if (_mediaplayer.isPlaying) {
        [_mediaplayer pause];
    } else {
        [_mediaplayer play];
    }

    if ([sender isKindOfClass:UIBarButtonItem.class]) {
        UIBarButtonItem *item = (UIBarButtonItem *)sender;
        [self changeImageFor:item];
    }
}

- (IBAction)closeAfterEnd:(id)sender
{
    if (!_mediaplayer.isPlaying) {
        [self closePlayback:sender];
    }
}

- (void)closePlayback:(id)sender
{
    [_mediaplayer stop];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)positionSliderAction:(UISlider *)sender
{
    /* Need to limit the number of events sent by the slider, since otherwise, the user
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

    if (_playPauseItem != nil) {
        [self changeImageFor:_playPauseItem];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    self.positionSlider.value = [_mediaplayer position];

    [UIView performWithoutAnimation:^{
        _timeDisplay.title = [[_mediaplayer remainingTime] stringValue];
    }];
}

- (void)toggleControlsVisible
{
    _controlsHidden = !_controlsHidden;
    [self.navigationController setNavigationBarHidden:_controlsHidden animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:_controlsHidden withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setToolbarHidden:_controlsHidden animated:YES];
}

@end
