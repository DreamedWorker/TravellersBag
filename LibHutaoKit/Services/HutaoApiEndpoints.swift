//
//  HutaoApiEndpoints.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/29.
//

import Foundation

class HutaoApiEndpoints {
    /// 胡桃云API端口
    static let shared = HutaoApiEndpoints()
    private init() {}
    
    private static var HomaSnapGenshin = "https://homa.snapgenshin.com"
    private static var HomaSnapPassport = "\(HutaoApiEndpoints.HomaSnapGenshin)/Passport"
    
    /// 登录胡桃通行证
    func login() -> String {
        return "\(HutaoApiEndpoints.HomaSnapPassport)/Login"
    }
    
    /// 获取用户信息
    func userInfo() -> String {
        return "\(HutaoApiEndpoints.HomaSnapPassport)/UserInfo"
    }
}
