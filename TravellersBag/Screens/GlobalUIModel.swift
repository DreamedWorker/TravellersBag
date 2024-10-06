//
//  GlobalUIModel.swift
//  TravellersBag
//a
//  Created by 鸳汐 on 2024/9/9.
//

import Foundation

class GlobalUIModel: ObservableObject {
    private init() {}
    static let exported = GlobalUIModel()
    
    @Published var showUI = false
    @Published var showAlert = GlobalAlertInfo()
    @Published var showLoading = GlobalLoadingInfo()
    
    var defAccount: ShequAccount? = nil
    
    func initSomething() {
        defAccount = CoreDataHelper.shared.fetchDefaultUser()
    }
    
    /// 是否拥有默认账号
    func hasDefAccount() -> Bool { return defAccount != nil }
    
    /// 刷新默认账号
    func refreshDefAccount() {
        defAccount = CoreDataHelper.shared.fetchDefaultUser()
    }
    
    /// 生成设备指纹（如果符合更新条件）
    func generateDeviceFp() async {
        let lastTime = Int64(UserDefaultHelper.shared.getValue(forKey: "lastTimeOfFpFetch", def: "0"))!
        let currentTime = Int64(Date().timeIntervalSince1970)
        if currentTime - lastTime >= 432000 {
            // 每5天更新一次设备指纹
            await TBEnv.default.updateDeviceFp()
            UserDefaultHelper.shared.setValue(forKey: "lastTimeOfFpFetch", value: "\(currentTime)")
        } else {
            print("还不需要更新指纹")
        }
        DispatchQueue.main.async {
            self.showUI = true
        }
    }
    
    /// 构建一个提示
    func makeAnAlert(type: Int, msg: String) {
        showAlert.msg = msg; showAlert.type = type; showAlert.showIt = true
    }
    
    /// 构建一个【加载中】提示
    func makeALoading(msg: String) {
        showLoading.msg = msg; showLoading.showIt = true
    }
    
    /// 信息弹窗结构体
    struct GlobalAlertInfo {
        /// 内容
        var msg: String
        
        /// 类型（1代表成功，3代表失败）
        var type: Int
        
        var showIt: Bool = false
        
        init(msg: String = "", type: Int = 2, showIt: Bool = false) {
            self.msg = msg
            self.type = type
            self.showIt = showIt
        }
    }
    
    struct GlobalLoadingInfo {
        /// 内容
        var msg: String
        var showIt: Bool = false
        
        init(msg: String = "", showIt: Bool = false) {
            self.msg = msg
            self.showIt = showIt
        }
    }
}
