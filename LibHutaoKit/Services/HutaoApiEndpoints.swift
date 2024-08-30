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
    private static var HomaSnapGachaLog = "\(HutaoApiEndpoints.HomaSnapGenshin)/GachaLog"
    
    /// 登录胡桃通行证
    func login() -> String {
        return "\(HutaoApiEndpoints.HomaSnapPassport)/Login"
    }
    
    /// 获取用户信息
    func userInfo() -> String {
        return "\(HutaoApiEndpoints.HomaSnapPassport)/UserInfo"
    }
    
    /// 抽卡记录日志
    func gachaEntries() -> String {
        return "\(HutaoApiEndpoints.HomaSnapGachaLog)/Entries"
    }
    
    /// 删除指定UID的云端祈愿数据
    func gachaDelete(uid: String) -> String {
        return "\(HutaoApiEndpoints.HomaSnapGachaLog)/Delete?Uid=\(uid)"
    }
    
    /// 上传祈愿数据
    func gachaUpload() -> String {
        return "\(HutaoApiEndpoints.HomaSnapGachaLog)/Upload"
    }
}
