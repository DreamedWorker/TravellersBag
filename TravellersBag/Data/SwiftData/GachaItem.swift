//
//  GachaItem.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/12/6.
//

import SwiftData

@Model
class GachaItem {
    var uid: String
    @Attribute(.unique) var id: String
    var name: String
    var time: String
    var rankType: String
    var itemType: String
    var gachaType: String
    
    init(uid: String, id: String, name: String, time: String, rankType: String, itemType: String, gachaType: String) {
        self.uid = uid
        self.id = id
        self.name = name
        self.time = time
        self.rankType = rankType
        self.itemType = itemType
        self.gachaType = gachaType
    }
}
