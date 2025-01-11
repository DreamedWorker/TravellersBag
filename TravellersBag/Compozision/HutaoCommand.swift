//
//  HutaoCommand.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/11.
//

import SwiftUI
import SwiftyJSON
import SwiftData

struct HutaoCommand: View {
    @Environment(\.modelContext) private var mc
    @Query private var hutaoPassports: [HutaoPassport]
    let show: () -> Void
    
    var body: some View {
        Button("app.command.hutao", action: {
            let lastLogin = UserDefaults.standard.integer(forKey: "hutaoLastLogin")
            let current = Int(Date().timeIntervalSince1970)
            if current - lastLogin >= 7200 {
                if UserDefaults.standard.bool(forKey: TBData.USE_KEY_CHAIN) {
                    Task {
                        if let account = try? TBHutaoService.read4keychain(
                            username: UserDefaults.standard.string(forKey: "keychain_name") ?? "") {
                            let result = try? await JSON(
                                data: TBHutaoService.loginPassport(username: account.username, passwordOri: account.password, writeKeychain: false))
                            if let surely = result {
                                if let ht = hutaoPassports.first {
                                    ht.auth = surely["data"].stringValue
                                    try! mc.save()
                                    UserDefaults.standard.set(current, forKey: "hutaoLastLogin")
                                }
                            }
                            DispatchQueue.main.async {
                                show()
                            }
                        } else {
                            DispatchQueue.main.async {
                                show()
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    show()
                }
            }
        })
    }
}
