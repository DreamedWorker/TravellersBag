//
//  AchieveItem.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/14.
//

import SwiftData

@Model
class AchieveItem {
    var archiveName: String
    var des: String
    var goal: Int
    var id: Int
    var order: Int
    var reward: Int
    var title: String
    var version: String
    var finished: Bool
    var timestamp: Int
    
    init(archiveName: String, des: String, goal: Int, id: Int, order: Int, reward: Int, title: String, version: String, finished: Bool, timestamp: Int) {
        self.archiveName = archiveName
        self.des = des
        self.goal = goal
        self.id = id
        self.order = order
        self.reward = reward
        self.title = title
        self.version = version
        self.finished = finished
        self.timestamp = timestamp
    }
}

@Model
class AchieveArchive {
    var archName: String
    
    init(archName: String) {
        self.archName = archName
    }
}
