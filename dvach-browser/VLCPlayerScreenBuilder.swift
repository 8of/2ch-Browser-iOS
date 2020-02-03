//
//  VLCPlayerScreenBuilder.swift
//  dvach-browser
//
//  Created by Victor Cebanu on 2/3/20.
//  Copyright © 2020 8of. All rights reserved.
//

import Foundation

final class VLCPlayerScreenBuilder: NSObject {
    @objc static func build(with videoURL: NSURL) -> VLCPlayerViewController {
        let vc = VLCPlayerViewController()
        let interactor = VLCPlayerInteractor(view: vc, videoURL: videoURL as URL)
        vc.interactor = interactor

        return vc
    }
}
