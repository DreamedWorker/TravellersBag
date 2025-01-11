//
//  HutaoLogin.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/5.
//

import SwiftUI
import SwiftData
import SwiftyJSON

struct HutaoLogin: View {
    @Environment(\.modelContext) private var mc
    @Query private var hutaoAccounts: [HutaoPassport]
    @StateObject private var vm = HutaoLoginViewModel()
    @Query private var mihoyoAccount: [MihoyoAccount]
    @State private var deleteCloud = false
    
    let dismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            if let surelyPassport = hutaoAccounts.first {
                VStack {
                    HStack {
                        Text(String.localizedStringWithFormat(NSLocalizedString("hutao.title", comment: ""), surelyPassport.normalizedUserName))
                            .font(.title2).bold()
                        Spacer()
                    }.padding(.bottom, 4)
                    Form {
                        HStack {
                            Label("hutao.ExpireAt", systemImage: "timer")
                            Spacer()
                            Text(surelyPassport.gachaLogExpireAt).foregroundStyle(.secondary)
                        }
                        if vm.gachaCloudRecord.count > 0 {
                            ForEach(vm.gachaCloudRecord) { entry in
                                HutaoCloudGachaRecordItem(
                                    entry: entry,
                                    deleteAction: { deleteCloud = true },
                                    syncAction: {
                                        Task {
                                            await vm.fetchRecordInfo(miAccount: mihoyoAccount.filter({ $0.active == true }).first, useNetwork: true)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .formStyle(.grouped)
                    .onAppear {
                        let mihoyoDefault = mihoyoAccount.filter({ $0.active == true }).first
                        Task {
                            await vm.fetchRecordInfo(miAccount: mihoyoDefault)
                        }
                    }
                }
                .onAppear {
                    vm.initIt(hutao: surelyPassport)
                }
            } else {
                Image("hutao_passport_login").resizable().frame(width: 72, height: 72)
                Text("hutao.login").font(.title).bold()
                Text("hutao.loginP")
                Form {
                    TextField("hutao.login.email", text: $vm.email)
                    SecureField("hutao.login.password", text: $vm.pasword)
                }.formStyle(.grouped)
                Text("hutao.loginP2").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("def.cancel", action: {
                    vm.dismissBefore(); dismiss()
                })
            })
            if vm.passport == nil {
                ToolbarItem(placement: .confirmationAction, content: {
                    Button("def.confirm", action: {
                        Task {
                            if let accountNew = await vm.tryLogin() {
                                if hutaoAccounts.isEmpty {
                                    mc.insert(accountNew); try! mc.save()
                                    vm.passport = accountNew
                                }
                            }
                        }
                    }).disabled(vm.email.isEmpty || vm.pasword.isEmpty)
                })
            }
            ToolbarItem(placement: .automatic, content: {
                Button("account.detail.logout", action: {
                    vm.dismissBefore(); dismiss()
                    for i in hutaoAccounts {
                        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                                    kSecAttrServer as String: tbService,
                                                    kSecAttrAccount as String: i.userName
                        ]
                        SecItemDelete(query as CFDictionary)
                        mc.delete(i)
                    }
                    try! mc.save()
                })
            })
        }
        .alert(vm.alertMate.msg, isPresented: $vm.alertMate.showIt, actions: {})
        .alert(
            "hutao.gacga.deleteDialog", isPresented: $deleteCloud,
            actions: {
                Button("def.cancel", role: .cancel, action: { deleteCloud = false })
                Button("def.confirm", role: .destructive,
                       action: { Task { await vm.deleteCloudRecord(hoyoAccount: mihoyoAccount.filter({ $0.active == true }).first!) } }
                )
            },
            message: { Text("hutao.gacga.deleteDialogP") }
        )
    }
}
