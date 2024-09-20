//
//  PassportModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/18.
//

import Foundation
import CoreData

class PassportModel: ObservableObject {
    var myHutaoAccount: HutaoAccount? = nil
    var dataManager: NSManagedObjectContext? = nil
    
    @Published var hasAccount = false
    @Published var showLogin = false
    @Published var loginInfo = loginModel()
    
    func initSomething(dm: NSManagedObjectContext) {
        dataManager = dm
        myHutaoAccount = try? dm.fetch(HutaoAccount.fetchRequest()).first
        hasAccount = myHutaoAccount != nil
    }
    
    func refreshAccount() {
        myHutaoAccount = try? dataManager!.fetch(HutaoAccount.fetchRequest()).first
        hasAccount = myHutaoAccount != nil
    }
    
    func tryLogin() async {
        do {
            let result = try await HutaoService.default.loginPassport(username: loginInfo.email, password: loginInfo.password)
            let userInfo = try await HutaoService.default.userInfo(auth: result["data"].stringValue)
            DispatchQueue.main.async { [self] in
                let neoAccount = HutaoAccount(context: dataManager!)
                neoAccount.auth = result["data"].stringValue
                neoAccount.gachaLogExpireAt = userInfo["GachaLogExpireAt"].stringValue
                neoAccount.isLicensedDeveloper = userInfo["IsLicensedDeveloper"].boolValue
                neoAccount.isMaintainer = userInfo["IsMaintainer"].boolValue
                neoAccount.normalizedUserName = userInfo["NormalizedUserName"].stringValue
                neoAccount.userName = userInfo["UserName"].stringValue
                let _ = CoreDataHelper.shared.save()
                showLogin = false
                refreshAccount()
                GlobalUIModel.exported.makeAnAlert(type: 1, msg: "操作完成")
                loginInfo.clearAll()
                UserDefaultHelper.shared.setValue(forKey: "hutaoLastLogin", value: String(Int(Date().timeIntervalSince1970)))
            }
        } catch {
            DispatchQueue.main.async {
                self.showLogin = false
                self.loginInfo.clearAll()
                GlobalUIModel.exported.makeAnAlert(type: 3, msg: "登录失败，\(error.localizedDescription)")
            }
        }
    }
    
    /// 退出登录
    func removeAccount() {
        if hasAccount {
            UserDefaultHelper.shared.setValue(forKey: TBEnv.USE_KEY_CHAIN, value: "no")
            UserDefaultHelper.shared.setValue(forKey: TBEnv.KEY_CHAIN_NAME, value: "")
            let copy = myHutaoAccount!
            dataManager!.delete(copy)
            let _ = CoreDataHelper.shared.save()
            myHutaoAccount = nil
            refreshAccount()
        } else {
            GlobalUIModel.exported.makeAnAlert(type: 3, msg: "你尚未登录！")
        }
    }
    
    func checkDeveloper() -> String {
        if let acc = myHutaoAccount {
            return (acc.isLicensedDeveloper) ? "是" : "否"
        } else {
            return "否"
        }
    }
    
    struct loginModel {
        var email: String
        var password: String
        
        init(email: String = "", password: String = "") {
            self.email = email
            self.password = password
        }
        
        mutating func clearAll() {
            email = ""; password = ""
        }
    }
}
