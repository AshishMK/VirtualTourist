//
//  PhotoData.swift
//  VirtualTourist
//
//  Created by Ashish Nautiyal on 2/15/19.
//  Copyright © 2019 Ashish  Nautiyal. All rights reserved.
//

import Foundation
struct  PhotoData : Codable {
    let url : String
    enum CodingKeys : String, CodingKey {
        case url = "url_m"
      
    }
}
