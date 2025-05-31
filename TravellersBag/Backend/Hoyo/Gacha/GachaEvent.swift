//
//  GachaEvent.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/6/1.
//

import Foundation

struct GachaEventElement: Codable {
    let name, version: String
    let order: Int
    let from, to: String
    let type: Int
    let upOrangeList: [Int]

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case version = "Version"
        case order = "Order"
        case from = "From"
        case to = "To"
        case type = "Type"
        case upOrangeList = "UpOrangeList"
    }
}

typealias GachaEvent = [GachaEventElement]
