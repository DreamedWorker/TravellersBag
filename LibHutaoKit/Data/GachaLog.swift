//
//  GachaLog.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/30.
//

import Foundation

struct HutaoGachaItem: Encodable {
    var GachaType: Int
    var QueryType: Int
    var ItemId: Int
    var Time: String
    var Id: Int
}

struct HutaoGachaUpload: Encodable {
    var Uid: String
    var Items: [HutaoGachaItem]
}
