//
//  Locations.swift
//  VirtualTourist
//
//  Created by Ashish Nautiyal on 2/15/19.
//  Copyright © 2019 Ashish  Nautiyal. All rights reserved.
//

import Foundation
struct Locations : Codable {
    let page : Int
    let pages : Int
    let photo : [PhotoData]
}
