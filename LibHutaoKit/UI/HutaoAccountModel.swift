//
//  HutaoAccountModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/29.
//

import Foundation
import CoreData

class HutaoAccountModel: ObservableObject {
    static let shared = HutaoAccountModel()
    private init() {}
    private var dataManager: NSManagedObjectContext?
    
    @Published var showLoginPane: Bool = false
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var hutaoAccount: HutaoAccount?
    @Published var showUI = false
    @Published var showLogoutAlert = false
    
    func initSomething(dm: NSManagedObjectContext) {
        dataManager = dm
        do {
            hutaoAccount = try dataManager!.fetch(HutaoAccount.fetchRequest()).first
            refreshUIState()
        } catch {
            HomeController.shared.showErrorDialog(
                msg: String.localizedStringWithFormat(
                    NSLocalizedString("hutaokit.init.err", comment: ""),
                    error.localizedDescription)
            )
        }
    }
    
    func tryLogin() async throws {
        let result = try await HutaoService.shared.login(username: email, password: password)
        let userInfo = try await HutaoService.shared.userInfo(auth: result["data"].stringValue)
        // 明文保存到钥匙串以备用（如果需要）
        let keytool = SecurityTool.shared.save(account: TravellersAccount(username: email, password: password))
        if keytool == noErr {
            LocalEnvironment.shared.setStringValue(key: LocalEnvironment.USE_KEY_CHAIN, value: "yes")
            LocalEnvironment.shared.setStringValue(key: LocalEnvironment.KEY_CHAIN_NAME, value: email)
        } else {
            LocalEnvironment.shared.setStringValue(key: LocalEnvironment.USE_KEY_CHAIN, value: "no")
        }
        DispatchQueue.main.async { [self] in
            let neoAccount = HutaoAccount(context: dataManager!)
            neoAccount.auth = result["data"].stringValue
            neoAccount.gachaLogExpireAt = userInfo["GachaLogExpireAt"].stringValue
            neoAccount.isLicensedDeveloper = userInfo["IsLicensedDeveloper"].boolValue
            neoAccount.isMaintainer = userInfo["IsMaintainer"].boolValue
            neoAccount.normalizedUserName = userInfo["NormalizedUserName"].stringValue
            neoAccount.userName = userInfo["UserName"].stringValue
            let _ = CoreDataHelper.shared.save()
            hutaoAccount = nil
            hutaoAccount = try? dataManager!.fetch(HutaoAccount.fetchRequest()).first
            showLoginPane = false
            refreshUIState()
            GlobalHutao.shared.refresh()
            HomeController.shared.showInfomationDialog(msg: NSLocalizedString("hutaokit.login.ok", comment: ""))
            email = ""; password = ""
        }
    }
    
    func removeAccount() {
        let copy = hutaoAccount!
        dataManager!.delete(copy)
        let _ = CoreDataHelper.shared.save()
        hutaoAccount = nil
        GlobalHutao.shared.hutao = nil
        showUI = false
    }
    
    private func refreshUIState() {
        if hutaoAccount != nil {
            showUI = true
        } else {
            showUI = false
        }
    }
}
