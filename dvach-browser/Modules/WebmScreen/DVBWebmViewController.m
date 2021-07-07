//
//  DVBWebmViewController.m
//  dvach-browser
//
//  Created by Andy on 07.07.2021.
//  Copyright © 2021 8of. All rights reserved.
//

#import <MobileVLCKit/MobileVLCKit.h>

#import "DVBWebmViewController.h"

@interface DVBWebmViewController () <VLCMediaPlayerDelegate>

@property (nonatomic, strong, nonnull) VLCMedia *media;
@property (nonatomic, strong, nonnull) VLCMediaListPlayer *player;

@property (nonatomic, strong, nonnull) UIProgressView *progressView;
@property (nonatomic, strong, nonnull) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation DVBWebmViewController

- (instancetype)initURL:(NSURL *)url {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _media = [VLCMedia mediaWithURL:url];
    }
    return self;
}

- (void)loadView {
    [self setupView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;

    VLCMediaList *mediaList = [[VLCMediaList alloc] initWithArray:@[self.media]];
    self.player.mediaList = mediaList;
    self.player.mediaPlayer.audio.volume = 0.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.player playMedia:self.media];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.player stop];
}

#pragma mark - VLCMediaPlayerDelegate

- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification {
    if (![aNotification.object isKindOfClass:[VLCMediaPlayer class]]) {
        return;
    }
    VLCMediaPlayer *player = aNotification.object;
    self.progressView.progress = player.position;
}

#pragma mark - Setup

- (void)setupView {
    self.view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view.backgroundColor = UIColor.blackColor;

    UIView *playerView = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    playerView.backgroundColor = UIColor.clearColor;

    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:indicatorView];

    [self.view addSubview:playerView];

    self.player = [[VLCMediaListPlayer alloc] initWithDrawable:playerView];
    self.player.repeatMode = VLCRepeatCurrentItem;
    self.player.mediaPlayer.delegate = self;

    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.progressView];

    NSArray<NSLayoutConstraint *> *constraints = @[
        [indicatorView.centerXAnchor constraintEqualToAnchor:playerView.centerXAnchor],
        [indicatorView.centerYAnchor constraintEqualToAnchor:playerView.centerYAnchor],

        [self.progressView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.progressView.bottomAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.bottomAnchor],
        [self.progressView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],

        [playerView.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor],
        [playerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [playerView.bottomAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.bottomAnchor],
        [playerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    ];
    [NSLayoutConstraint activateConstraints:constraints];

    [indicatorView startAnimating];

    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(videoTap)];
    [playerView addGestureRecognizer:self.tapGestureRecognizer];
}

#pragma mark - Actions

- (void)videoTap {
    BOOL isMuted = self.player.mediaPlayer.audio.volume < 5.0;
    self.player.mediaPlayer.audio.volume = isMuted ? 100.0 : 0.0;
}

@end
