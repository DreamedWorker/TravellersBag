//
//  AccountModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/1.
//

import SwiftData

@Model
/// 米游社账号模型
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
