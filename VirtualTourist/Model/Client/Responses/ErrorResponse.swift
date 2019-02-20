//
//  ErrorResponse.swift
//  VirtualTourist
//
//  Created by Ashish Nautiyal on 2/16/19.
//  Copyright © 2019 Ashish  Nautiyal. All rights reserved.
//

import Foundation
struct ErrorResponse : Codable{
    let code: Int
    let message : String
}
extension ErrorResponse: LocalizedError {
    var errorDescription : String? {
        return message
    }
    
}
