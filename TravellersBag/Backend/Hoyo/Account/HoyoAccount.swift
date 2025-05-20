//
//  HoyoAccount.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/18.
//

import SwiftData

@Model
class HoyoAccount: @unchecked Sendable {
    var activedAccount: Bool
    var bbsHeadImg: String
    var bbsNicname: String
    var cookie: AccountCookie
    var game: AccountGameBreif
    
    init(activedAccount: Bool, bbsHeadImg: String, bbsNicname: String, cookie: AccountCookie, game: AccountGameBreif) {
        self.activedAccount = activedAccount
        self.bbsHeadImg = bbsHeadImg
        self.bbsNicname = bbsNicname
        self.cookie = cookie
        self.game = game
    }
    
    /// 在「我的通行证」页面 用于刚加载时的留空
    static func buildDefaultAccount() -> HoyoAccount {
        return .init(
            activedAccount: false, bbsHeadImg: "", bbsNicname: "Please choose",
            cookie: .init(cookieToken: "", gameToken: "", ltoken: "", mid: "", stoken: "", stuid: ""),
            game: .init(genshinNicname: "", genshinPicID: "", genshinUID: "", level: "", serverName: "", serverRegion: "")
        )
    }
}

extension HoyoAccount {
    struct AccountCookie: Codable {
        var cookieToken: String
        var gameToken: String
        var ltoken: String
        var mid: String
        var stoken: String
        var stuid: String
    }
    
    struct AccountGameBreif: Codable {
        var genshinNicname: String
        var genshinPicID: String
        var genshinUID: String
        var level: String
        var serverName: String
        var serverRegion: String
    }
}
