//
//  AccountPart.swift
//  TravellersBag
//  米游社账号所需的其他包装属性
//  Created by 鸳汐 on 2024/11/1.
//

import Foundation

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
