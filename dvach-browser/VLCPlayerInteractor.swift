//
//  VLCPlayerInteractor.swift
//  dvach-browser
//
//  Created by Victor Cebanu on 2/3/20.
//  Copyright © 2020 8of. All rights reserved.
//

import Foundation

final class VLCPlayerInteractor {
    var videoURL: URL

    private weak var view: VLCPlayerViewInput?

    init(view: VLCPlayerViewInput?,
         videoURL: URL) {
        self.view = view
        self.videoURL = videoURL

    }
}

extension VLCPlayerInteractor: VLCPlayerViewOutput {
    func viewDidLoad() {
        view?.playVideo(from: videoURL)
    }
}
