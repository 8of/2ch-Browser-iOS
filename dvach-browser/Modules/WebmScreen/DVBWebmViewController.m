//
//  DVBWebmViewController.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 02/03/2017.
//  Copyright © 2017 8of. All rights reserved.
//

#import <OGVKit/OGVKit.h>
#import <PureLayout/PureLayout.h>

#import "DVBCommon.h"
#import "DVBConstants.h"
#import "DVBWebmViewController.h"

@interface DVBWebmViewController () <OGVPlayerDelegate>

@property (nonatomic, strong, nonnull) NSURL *url;
@property (nonatomic, strong, nonnull) OGVPlayerView *playerView;

@end

@implementation DVBWebmViewController

- (instancetype)initWithUrl:(NSURL *)url
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _url = url;
  }
  return self;
}

#pragma mark - Life circle

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
  [self setupCloseButton];
  _playerView = [[OGVPlayerView alloc] initWithFrame:self.view.bounds];
  _playerView.translatesAutoresizingMaskIntoConstraints = NO;
  _playerView.delegate = self;
  [self.view addSubview:_playerView];
  [_playerView autoPinEdgesToSuperviewEdges];
  _playerView.sourceURL = _url;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [_playerView play];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [_playerView pause];
}

#pragma mark - Actions

- (void)setupCloseButton
{
  UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:NSLS(@"BUTTON_CLOSE") style:UIBarButtonItemStylePlain target:self action:@selector(closeVC)];
  [self.navigationItem setLeftBarButtonItem:closeItem];
}

- (void)closeVC
{
  [_playerView pause];
  [self dismissViewControllerAnimated:YES
                           completion:nil];
}

#pragma mark - OGVPlayerDelegate

- (void)ogvPlayerDidEnd:(OGVPlayerView *)sender
{
  [self closeVC];
}

- (void)ogvPlayerControlsWillHide:(OGVPlayerView *)sender
{
  [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)ogvPlayerControlsWillShow:(OGVPlayerView *)sender
{
  [self.navigationController setNavigationBarHidden:NO animated:YES];
}

@end
