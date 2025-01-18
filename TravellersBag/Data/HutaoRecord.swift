//
//  HutaoRecord.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/2.
//

import Foundation

struct HutaoRecordEntry: Identifiable {
    var id: String
    var Excluded: Bool
    var ItemCount: Int
}

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
