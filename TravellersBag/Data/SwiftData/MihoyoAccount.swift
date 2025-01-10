//
//  MihoyoAccount.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/10.
//

import Foundation
import SwiftData

@Model
class MihoyoAccount {
    var active: Bool
    @Attribute(.unique) var stuidForTest: String //重复存储一次，用于判断账号唯一性
    var cookies: AccountCookie
    var gameInfo: AccountGameBreif
    var misheHead: String
    var misheNicname: String
    
    init(active: Bool, stuidForTest: String, cookies: AccountCookie, gameInfo: AccountGameBreif, misheHead: String, misheNicname: String) {
        self.active = active
        self.stuidForTest = stuidForTest
        self.cookies = cookies
        self.gameInfo = gameInfo
        self.misheHead = misheHead
        self.misheNicname = misheNicname
    }
}

/// 账号Cookie和相关信息
struct AccountCookie: Codable {
    var cookieToken: String
    var gameToken: String
    var ltoken: String
    var mid: String
    var stoken: String
    var stuid: String
}

/// 游戏信息简介
struct AccountGameBreif: Codable {
    var genshinNicname: String
    var genshinPicID: String
    var genshinUID: String
    var level: String
    var serverName: String
    var serverRegion: String
}
