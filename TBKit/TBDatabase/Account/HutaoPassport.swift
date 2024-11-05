//
//  HutaoPassport.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/5.
//

import SwiftData

@Model
class HutaoPassport {
    var auth: String
    var gachaLogExpireAt: String
    var isLicensedDeveloper: Bool
    var isMaintainer: Bool
    var normalizedUserName: String
    var userName: String
    
    init(auth: String, gachaLogExpireAt: String, isLicensedDeveloper: Bool, isMaintainer: Bool, normalizedUserName: String, userName: String) {
        self.auth = auth
        self.gachaLogExpireAt = gachaLogExpireAt
        self.isLicensedDeveloper = isLicensedDeveloper
        self.isMaintainer = isMaintainer
        self.normalizedUserName = normalizedUserName
        self.userName = userName
    }
}
