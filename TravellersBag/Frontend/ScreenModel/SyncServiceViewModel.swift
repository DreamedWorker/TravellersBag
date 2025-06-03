//
//  SyncServiceViewModel.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/6/2.
//

import Foundation
import Security
import SwiftData

class SyncServiceViewModel: ObservableObject, @unchecked Sendable {
    @Published var uiState: SyncServiceUiSate = .init()
    var operation: ModelContext? = nil
    
    func initSomething(model: ModelContext) {
        operation = model
    }
    
    func savePassword2Keychain() {
        let password = uiState.password.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: uiState.username,
            kSecAttrServer as String: "TravellersBag"
        ]
        SecItemDelete(query as CFDictionary)
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: uiState.username,
            kSecAttrServer as String: "TravellersBag",
            kSecValueData as String: password
        ]
        let status = SecItemAdd(attributes as CFDictionary, nil)
        print(status)
    }
    
    func readPassword4Keychain(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: account,
            kSecAttrServer as String: "TravellersBag",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess {
            if let data = item as? Data,
               let password = String(data: data, encoding: .utf8) {
                return password
            }
        }
        return nil
    }
    
    func login(callback: @escaping @MainActor @Sendable (HutaoPassport) -> Void) async {
        do {
            let auth = try await HutaoService.tryLogin(
                username: uiState.username,
                password: uiState.password
            )
            let info = try await HutaoService.fetchUserInfo(auth: auth)
            let tempAccount = HutaoPassport(
                auth: auth, gachaLogExpireAt: info.data.gachaLogExpireAt,
                isLicensedDeveloper: info.data.isLicensedDeveloper, isMaintainer: info.data.isMaintainer,
                normalizedUserName: info.data.normalizedUserName, userName: info.data.userName
            )
            savePassword2Keychain()
            DispatchQueue.main.async {
                callback(tempAccount)
                self.uiState.username = ""
                self.uiState.password = ""
            }
        } catch {
            DispatchQueue.main.async {
                self.uiState.alertMate.showAlert(msg: error.localizedDescription, type: .Error)
            }
        }
    }
    
    func fetchPersonalGachaEntries(account: HutaoPassport, refresh: @escaping @MainActor @Sendable (String) -> Void) async {
        do {
            let result = try await HutaoService.fetchGachaEntries(auth: account.auth)
            DispatchQueue.main.async {
                self.uiState.gachaEntries.removeAll()
                self.uiState.gachaEntries.append(contentsOf: result.data)
            }
        } catch {
            do {
                let username = account.userName
                let password = readPassword4Keychain(account: username)
                if let password = password {
                    let auth = try await HutaoService.tryLogin(username: username, password: password)
                    DispatchQueue.main.async {
                        refresh(auth)
                    }
                    let result = try await HutaoService.fetchGachaEntries(auth: auth)
                    DispatchQueue.main.async {
                        self.uiState.gachaEntries.removeAll()
                        self.uiState.gachaEntries.append(contentsOf: result.data)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.uiState.alertMate.showAlert(
                        msg: NSLocalizedString("sync.error.needLogin", comment: ""),
                        type: .Error
                    )
                }
            }
        }
    }
}

extension SyncServiceViewModel {
    struct SyncServiceUiSate {
        var username: String = ""
        var password: String = ""
        var alertMate: AlertMate = .init()
        var gachaEntries: [HutaoService.HutaoGachaEntry.Datum] = []
    }
}
