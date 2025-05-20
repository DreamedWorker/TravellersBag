//
//  AccountView.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/18.
//

import SwiftUI
import SwiftData
import Kingfisher

struct AccountView: View {
    @Environment(\.modelContext) private var operate
    @Query private var accounts: [HoyoAccount]
    @StateObject private var viewModel = AccountViewModel()
    @State private var selectedAccount: HoyoAccount? = nil
    @State private var showLogin: Bool = false
    
    var body: some View {
        NavigationStack {
            HSplitView {
                List(selection: $selectedAccount) {
                    ForEach(accounts) { account in
                        Label(
                            title: { Text(account.bbsNicname).padding(.leading, 16) },
                            icon: {
                                KFImage(URL(string: account.bbsHeadImg))
                                    .placeholder({ ProgressView() })
                                    .loadDiskFileSynchronously(true)
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .padding(.leading, 16)
                            }
                        ).tag(account)
                    }
                }.frame(minWidth: 150, maxWidth: 170, maxHeight: .infinity)
                VStack {
                    if let account = selectedAccount {
                        Form {
                            Section { // 首部图片
                                HStack {
                                    Spacer()
                                    VStack {
                                        KFImage.url(URL(string: account.bbsHeadImg))
                                            .loadDiskFileSynchronously(true)
                                            .resizable()
                                            .clipShape(.circle)
                                            .frame(width: 92, height: 92)
                                        Text(account.bbsNicname).font(.largeTitle.bold())
                                    }
                                    Spacer()
                                }.padding()
                            }
                            Section { // 敏感性较低的信息
                                TextInfoTile(titleKey: "account.info.gameNick", value: account.game.genshinNicname)
                                TextInfoTile(titleKey: "account.info.gameUID", value: account.game.genshinUID)
                                TextInfoTile(titleKey: "account.info.gameBasic", value: "\(account.game.serverName) | Lv.\(account.game.level)")
                            }
                            Section { // 检查账号联通性
                                VStack {
                                    HStack {
                                        Button("account.action.checkAccessible", action: {
                                            Task {
                                                await viewModel.checkAccountState(account: account) { needChange in
                                                    DispatchQueue.main.async { [self] in
                                                        selectedAccount = nil
                                                        operate.delete(account)
                                                        try! operate.save()
                                                        if !accounts.isEmpty {
                                                            if needChange {
                                                                let first = accounts.first!
                                                                first.activedAccount = true
                                                                try! operate.save()
                                                            }
                                                        }
                                                        viewModel.uiState.uiAlert.showAlert(
                                                            msg: NSLocalizedString("account.info.checkAccessibleFailed", comment: "")
                                                        )
                                                    }
                                                }
                                            }
                                        })
                                        Spacer()
                                    }
                                    HStack {
                                        Text("account.tip.checkAccessible").font(.footnote).foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                }
                            }
                            Section { // 其他功能
                                HStack {
                                    Spacer()
                                    Button("account.action.def", action: {
                                        let ori = accounts.filter({ $0.activedAccount }).first!
                                        ori.activedAccount = false
                                        account.activedAccount = true
                                        try! operate.save()
                                    }).disabled(account.activedAccount)
                                    Button("account.action.copy", action: {
                                        let pasteBoard = NSPasteboard.general
                                        pasteBoard.clearContents()
                                        pasteBoard.setString(
                                            RequestBuilder.RequestingUser(
                                                uid: account.cookie.stuid, stoken: account.cookie.stoken, mid: account.cookie.mid
                                            ).toRequestHeader(),
                                            forType: .string
                                        )
                                        viewModel.uiState.uiAlert.showAlert(msg: "Done")
                                    })
                                    Button("account.action.delete", role: .destructive, action: {
                                        selectedAccount = nil
                                        let needChange = account.activedAccount
                                        operate.delete(account)
                                        try! operate.save()
                                        if !accounts.isEmpty {
                                            if needChange {
                                                let first = accounts.first!
                                                first.activedAccount = true
                                                try! operate.save()
                                            }
                                        }
                                    })
                                }
                            }
                        }
                        .formStyle(.grouped)
                    } else {
                        ContentUnavailableView(
                            "account.error.unknown",
                            systemImage: "person.crop.circle.badge.exclamationmark",
                            description: Text("account.error.unknownExp")
                        )
                    }
                }
                .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                .alert(
                    viewModel.uiState.uiAlert.title,
                    isPresented: $viewModel.uiState.uiAlert.showIt,
                    actions: {},
                    message: { Text(viewModel.uiState.uiAlert.msg) }
                )
                .onAppear {
                    if !accounts.isEmpty {
                        selectedAccount = accounts.first!
                    }
                }
            }
        }
        .sheet(isPresented: $showLogin, content: { LoginNewAccount })
        .toolbar {
            ToolbarItem(placement: .primaryAction, content: {
                Button(action: { showLogin = true }, label: { Image(systemName: "plus") }).help("account.help.add")
            })
        }
        .navigationTitle(Text("account.title"))
    }
    
    private var LoginNewAccount: some View {
        
        return NavigationStack {
            Text("account.login.title").font(.largeTitle.bold()).padding(.bottom)
            Image(nsImage: viewModel.uiState.qrcode ?? NSImage(size: NSSize(width: 36, height: 36)))
                .resizable().frame(width: 128, height: 128)
                .onAppear {
                    Task.detached {
                        await viewModel.fetchImage()
                    }
                }
            Text("account.login.tip.login").font(.footnote).foregroundStyle(.secondary).padding(.bottom)
            HStack(spacing: 16) {
                Button("account.login.action.reobtain", action: {
                    Task.detached { await viewModel.fetchImage() }
                })
                Button("account.login.action.confirm", action: {
                    viewModel.login(accounts: accounts) { loginedAccount in
                        DispatchQueue.main.async {
                            self.operate.insert(loginedAccount)
                            try! self.operate.save()
                            self.showLogin = false
                        }
                    }
                }).buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("app.close", action: { showLogin = false })
            })
        }
        .alert(
            viewModel.uiState.loginAlert.title,
            isPresented: $viewModel.uiState.loginAlert.showIt,
            actions: {},
            message: { Text(viewModel.uiState.loginAlert.msg) }
        )
    }
}

extension AccountView {
    struct TextInfoTile: View {
        let titleKey: String
        let value: String
        
        var body: some View {
            HStack {
                Text(NSLocalizedString(titleKey, comment: ""))
                Spacer()
                Text(value).foregroundStyle(.secondary)
            }
        }
    }
}
