//
//  AccountViewModel.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/19.
//

import Foundation
import AppKit

class AccountViewModel: ObservableObject, @unchecked Sendable {
    @Published var uiState: AccountUiState = .init()
    
    func checkAccountState(account: HoyoAccount, remove: @escaping @Sendable (Bool) -> Void) async {
        do {
            _ = try await HoyoAccountHelper.fetchLtoken(uid: account.cookie.stuid, stoken: account.cookie.stoken, mid: account.cookie.mid)
            await MainActor.run {
                uiState.uiAlert.showAlert(msg: NSLocalizedString("account.info.checkAccessibleOK", comment: ""))
            }
        } catch { // 需要更新账号
            remove(account.activedAccount)
        }
    }
    
    func fetchImage() async {
        do {
            guard let nsImageCode = try await HoyoAccountHelper.generateQRCode() else {
                throw NSError(domain: "AccountLogin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch qrcode."])
            }
            await MainActor.run {
                uiState.qrcode = nsImageCode
            }
        } catch {
            DispatchQueue.main.async {
                self.uiState.loginAlert.showAlert(msg: error.localizedDescription, type: .Error)
            }
        }
    }
    
    func login(accounts: [HoyoAccount], saveAccount: @escaping @Sendable (HoyoAccount) -> Void) {
        Task.detached {
            let copyAccounts = accounts
            do {
                try await HoyoAccountHelper.login(
                    checkHasSame: { it in
                        let result = copyAccounts.filter({ $0.cookie.stuid == it })
                        if result.isEmpty {
                            return false
                        } else {
                            return true
                        }
                    }) { hoyoAccount in
                        let activedAccount = copyAccounts.filter({ $0.activedAccount })
                        let preparedAccount = hoyoAccount
                        if activedAccount.isEmpty {
                            preparedAccount.activedAccount = true
                        }
                        saveAccount(preparedAccount)
                    }
            } catch {
                DispatchQueue.main.async {
                    self.uiState.loginAlert.showAlert(msg: error.localizedDescription, type: .Error)
                }
            }
        }
    }
}

extension AccountViewModel {
    struct AccountUiState {
        var uiAlert: AlertMate = .init()
        var loginAlert: AlertMate = .init()
        var qrcode: NSImage? = nil
    }
}
