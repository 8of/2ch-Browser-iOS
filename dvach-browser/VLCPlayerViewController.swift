//
//  VLCPlayerViewController.swift
//  dvach-browser
//
//  Created by Victor Cebanu on 2/3/20.
//  Copyright © 2020 8of. All rights reserved.
//

import Foundation

final class VLCPlayerViewController: UIViewController, VLCPlayerViewInput {
    var interactor: VLCPlayerViewOutput!
    var player: VLCMediaPlayer?
    var playerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPlayerView()
        setupPlayer()
        interactor.viewDidLoad()
    }

    // Private methods

    private func setupPlayerView() {
        playerView = UIView(frame: view.bounds)
        view.addSubview(playerView)
    }

    private func setupPlayer() {
        player = VLCMediaPlayer()
        player?.delegate = self
        player?.drawable = playerView
    }

    // VLCPlayerViewInput
    func playVideo(from url: URL) {
        let media = VLCMedia(url: url)
        player?.media = media
        player?.play()
    }

}

extension VLCPlayerViewController: VLCMediaPlayerDelegate {

}

