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

    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var progressBar: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var timeLeftLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var muteButton: UIButton!

    private let defaultVideoJumpInterval: Int32 = 10 // TODO: Read from settings

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPlayer()
        interactor.viewDidLoad()
    }

    // IBAction

    @IBAction func progressBarWasMoved(_ sender: UISlider) {
        player?.position = sender.value

    }

    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
        (player?.isPlaying ?? false) ? player?.pause() : player?.play()
        updatePlayIcon()
    }

    @IBAction func backwardButtonPressed(_ sender: Any) {
        player?.jumpBackward(defaultVideoJumpInterval)
    }

    @IBAction func forwardButtonPressed(_ sender: Any) {
        player?.jumpForward(defaultVideoJumpInterval)
    }

    @IBAction func muteButtonPressed(_ sender: Any) {
        if (player?.audio.volume ?? 0) < 1 {
            player?.audio.volume = 100
        } else {
            player?.audio.volume = -100
        }
        updateMuteIcon()
    }

    // Private methods

    private var playIcon: PlayerIcons {
        guard let isPlaying = player?.isPlaying else { return .play }
        return isPlaying ? .play : .pause
    }

    private var muteIcon: PlayerIcons {
        let isMuted = (player?.audio.volume ?? 0) < 1
        return isMuted ? .unmute : .mute
    }

    private func updatePlayIcon() {
        playButton.setImage(UIImage(named: playIcon.rawValue), for: .normal)
    }

    private func updateMuteIcon() {
        muteButton.setImage(UIImage(named: muteIcon.rawValue), for: .normal)
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
        player?.audio.volume = -100
        player?.play()
        updateMuteIcon()
        updatePlayIcon()
    }
}

extension VLCPlayerViewController: VLCMediaPlayerDelegate {
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        currentTimeLabel.text = player?.time.stringValue ?? "--:--"
        timeLeftLabel.text = player?.remainingTime.stringValue ?? "--:--"
        progressBar.value = player?.position ?? 0.5
    }
}

private enum PlayerIcons: String {
    case play
    case pause
    case mute
    case unmute
}
