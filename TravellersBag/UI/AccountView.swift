//
//  AccountView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/10.
//

import SwiftUI
import SwiftData
import Kingfisher

struct AccountView: View {
    @Environment(\.modelContext) private var tbDao
    @Query private var allUsers: [MihoyoAccount]
    
    @StateObject private var vm = AccountViewModel()
    @State private var selectedAccount: MihoyoAccount? = nil
    
    var body: some View {
        NavigationStack {
            HSplitView {
                VStack {
                    List(selection: $selectedAccount) {
                        ForEach(allUsers) { account in
                            Label(
                                title: { Text(account.misheNicname).padding(.leading, 16) },
                                icon: {
                                    KFImage(URL(string: account.misheHead))
                                        .placeholder({ ProgressView() })
                                        .loadDiskFileSynchronously(true)
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                        .padding(.leading, 16)
                                }
                            ).tag(account)
                        }
                    }
                }
                .frame(minWidth: 150, maxWidth: 170, maxHeight: .infinity)
                VStack {
                    if let account = selectedAccount {
                        AccountDetail(
                            setDefaultAccount: {
                                if !account.active {
                                    let actived = Query(filter: #Predicate<MihoyoAccount> { $0.active == true })
                                    for i in actived.wrappedValue {
                                        i.active = false
                                    }
                                    account.active = true
                                    try! tbDao.save()
                                } else {
                                    vm.alertMate.showAlert(msg: NSLocalizedString("account.error.setDef", comment: ""))
                                }
                            },
                            logout: { act in
                                let isDef = account.active
                                tbDao.delete(act); try! tbDao.save()
                                if allUsers.count == 0 {
                                    NSApplication.shared.terminate(self)
                                } else {
                                    if isDef {
                                        let neoAccount = allUsers.first!
                                        neoAccount.active = true
                                        try! tbDao.save()
                                        vm.alertMate.showAlert(msg: NSLocalizedString("account.info.reDef", comment: ""))
                                    }
                                }
                            },
                            checkState: { act in
                                Task {
                                    let neoAccount = await vm.checkAccountState(account: act)
                                    if let checked = neoAccount {
                                        selectedAccount = nil
                                        let inListAccount = allUsers.first(where: { $0.stuidForTest == checked.stuidForTest })!
                                        tbDao.delete(inListAccount); tbDao.insert(checked)
                                        try! tbDao.save()
                                    }
                                }
                            },
                            account: account
                        )
                    } else {
                        VStack {
                            Image("account_nothing_to_show").resizable().frame(width: 72, height: 72)
                            Text("account.nothing.title").font(.title2).bold()
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
                    }
                }
                .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    if allUsers.count > 0 { // 自动选择列表第一个
                        selectedAccount = allUsers[0]
                    }
                }
            }
        }
        .navigationTitle(Text("home.sidebar.account"))
        .alert(vm.alertMate.msg, isPresented: $vm.alertMate.showIt, actions: {})
        .sheet(isPresented: $vm.loginByQr, content: { LoginByQr })
        .sheet(isPresented: $vm.loginByCookie, content: { LoginByCookie })
        .toolbar {
            ToolbarItem {
                Button(
                    action: {
                        Task { await vm.getQrAndShowWindow() }
                    },
                    label: { Image(systemName: "qrcode.viewfinder").help("account.side.loginByQr") }
                )
            }
            ToolbarItem {
                Button(
                    action: {
                        vm.loginByCookie = true
                    },
                    label: { Image(systemName: "cooktop").help("account.side.loginByCookie") }
                )
            }
        }
    }
    
    private var LoginByQr: some View {
        return NavigationStack {
            Text("account.side.loginByQr").font(.title).bold()
            Image(nsImage: vm.loginQRCode ?? NSImage()).resizable().frame(width: 128, height: 128)
            ZStack {}.frame(height: 16)
            Text("account.qr.tip").font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .confirmationAction, content: {
                Button(
                    "def.confirm",
                    action: {
                        Task {
                            let data = await vm.queryStatusAndLogin(
                                hasSame: { uid in return allUsers.contains(where: { $0.stuidForTest == uid })},
                                counts: allUsers.count
                            )
                            DispatchQueue.main.async {
                                if let account = data {
                                    self.tbDao.insert(account); try? self.tbDao.save()
                                }
                                self.vm.loginByQr = false; self.vm.loginQRCode = nil
                            }
                        }
                    })
            })
            ToolbarItem(placement: .cancellationAction, content: {
                Button("def.cancel", action: { vm.loginByQr = false; vm.loginQRCode = nil })
            })
            ToolbarItem(placement: .automatic, content: {
                Button("account.qr.refresh", action: {
                    Task { await vm.getQrAndShowWindow() }
                } )
            })
        }
    }
    
    private var LoginByCookie: some View {
        return NavigationStack {
            Text("account.side.loginByCookie").font(.title).bold()
            Form {
                TextField("account.cookie.input", text: $vm.loginCookie)
            }.formStyle(.grouped)
            Text("account.cookie.tip").foregroundStyle(.secondary).font(.footnote)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("def.cancel", action: { vm.loginByCookie = false; vm.loginCookie = "" })
            })
            ToolbarItem(placement: .confirmationAction, content: {
                Button("def.confirm", action: {
                    Task {
                        let data = await vm.loginByCookieFunc(
                            hasSame: { uid in return allUsers.contains(where: { $0.stuidForTest == uid })},
                            counts: allUsers.count
                        )
                        DispatchQueue.main.async {
                            if let account = data {
                                self.tbDao.insert(account); try? self.tbDao.save()
                            }
                            self.vm.loginByCookie = false; self.vm.loginCookie = ""
                        }
                    }
                }).disabled(vm.loginCookie.isEmpty)
            })
        }
    }
}

#Preview {
    AccountView()
}
