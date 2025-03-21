//
//  HutaoApiEndpoints.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/29.
//

import Foundation

final class HutaoApiEndpoints: Sendable {
    /// 胡桃云API端口
    static let shared = HutaoApiEndpoints()
    private init() {}
    
    private static let HomaSnapGenshin = "https://homa.snapgenshin.com"
    private static let HomaSnapPassport = "\(HutaoApiEndpoints.HomaSnapGenshin)/Passport"
    private static let HomaSnapGachaLog = "\(HutaoApiEndpoints.HomaSnapGenshin)/GachaLog"
    
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
    
    /// 云端记录末尾Id
    func gachaEndIds(uid: String) -> String {
        return "\(HutaoApiEndpoints.HomaSnapGachaLog)/EndIds?Uid=\(uid)"
    }
    
    /// 获取云端祈愿记录
    func gachaRetrieve() -> String {
        return "\(HutaoApiEndpoints.HomaSnapGachaLog)/Retrieve"
    }
}
