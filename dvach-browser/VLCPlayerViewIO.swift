//
//  VLCPlayerViewIO.swift
//  dvach-browser
//
//  Created by Victor Cebanu on 2/3/20.
//  Copyright © 2020 8of. All rights reserved.
//

import Foundation

protocol VLCPlayerViewInput: class {
    func playVideo(from url: URL)
}

protocol VLCPlayerViewOutput: class {
    func viewDidLoad()
}
