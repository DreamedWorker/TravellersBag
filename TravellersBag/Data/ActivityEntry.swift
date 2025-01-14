//
//  ActivityEntry.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/14.
//

import Foundation

struct ActivityEntry: Identifiable, Hashable {
    var id: String
    var name: String
    var version: String
    var banner: String
    var from: Date
    var to: Date
    var type: Int
    var oragon: [Int]
    var purple: [Int]
}
