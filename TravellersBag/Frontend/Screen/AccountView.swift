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
    @State private var showLogin: Bool = false
    @State private var selectedAccount: HoyoAccount? = nil
    
    var body: some View {
        NavigationStack {
            if accounts.isEmpty {
                ContentUnavailableView("account.empty", systemImage: "person.crop.circle.badge.plus")
            } else {
                HSplitView {
                    List(selection: $selectedAccount, content: {
                        ForEach(accounts) { account in
                            AccountTile(account: account).tag(account)
                        }
                    })
                    .listStyle(.sidebar)
                    .frame(minWidth: 150, maxWidth: 170, maxHeight: .infinity)
                    VStack {
                        if let account = selectedAccount {
                            AccountDetail(
                                account: account,
                                setDefAccount: {
                                    let ori = accounts.filter({ $0.activedAccount }).first!
                                    ori.activedAccount = false
                                    account.activedAccount = true
                                    try! operate.save()
                                },
                                deleteAccount: {
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
                                }
                            )
                        } else {
                            ContentUnavailableView(
                                "account.error.unknown",
                                systemImage: "person.crop.circle.badge.exclamationmark",
                                description: Text("account.error.unknownExp")
                            )
                        }
                    }
                    .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle(Text("account.title"))
        .toolbar {
            ToolbarItem(placement: .primaryAction, content: {
                Button(action: { showLogin = true }, label: { Image(systemName: "plus") }).help("account.help.add")
            })
        }
        .sheet(isPresented: $showLogin, content: {
            LoginPane(currentAccounts: accounts, dismissIt: { showLogin = false })
        })
    }
}

fileprivate struct AccountDetail: View {
    @Environment(\.modelContext) private var operate
    @State private var mate: AlertMate = .init()
    var account: HoyoAccount
    let setDefAccount: () -> Void
    let deleteAccount: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack {
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
                Form {
                    Section { // 敏感性较低的信息
                        TextInfoTile(titleKey: "account.info.gameNick", value: account.game.genshinNicname)
                        TextInfoTile(titleKey: "account.info.gameUID", value: account.game.genshinUID)
                        TextInfoTile(titleKey: "account.info.gameBasic", value: "\(account.game.serverName) | Lv.\(account.game.level)")
                    }
                    Section { // 刷新 SToken
                        VStack {
                            HStack {
                                Spacer()
                                Button("account.action.checkAccessible", action: {
                                    Task {
                                        do {
                                            let neoStoken = try await HoyoAccountHelper.fetchUserSToken(uid: account.cookie.stuid, token: account.cookie.gameToken)
                                            let ckToken = try await HoyoAccountHelper.fetchCookieToken(uid: account.cookie.stuid, token: account.cookie.gameToken)
                                            let lToken = try await HoyoAccountHelper.fetchLtoken(uid: account.cookie.stuid, stoken: neoStoken.data.token.token, mid: account.cookie.mid)
                                            DispatchQueue.main.async { [self] in
                                                account.cookie.stoken = neoStoken.data.token.token
                                                account.cookie.cookieToken = ckToken.data.cookieToken
                                                account.cookie.ltoken = lToken.data.ltoken
                                                try! operate.save()
                                                mate.showAlert(msg: "app.done")
                                            }
                                        } catch {
                                            DispatchQueue.main.async { [self] in
                                                mate.showAlert(
                                                    msg: String.localizedStringWithFormat(
                                                        NSLocalizedString("account.error.refresh", comment: ""), error.localizedDescription
                                                    ),
                                                    type: .Error
                                                )
                                            }
                                        }
                                    }
                                })
                            }
                            HStack {
                                Text("account.tip.checkAccessible").font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Section {
                        HStack {
                            Button("account.action.def", action: setDefAccount).disabled(account.activedAccount)
                            Spacer()
                            Button("account.action.copy", action: {
                                let pasteBoard = NSPasteboard.general
                                pasteBoard.clearContents()
                                pasteBoard.setString(
                                    RequestBuilder.RequestingUser(
                                        uid: account.cookie.stuid, stoken: account.cookie.stoken, mid: account.cookie.mid
                                    ).toRequestHeader(),
                                    forType: .string
                                )
                                mate.showAlert(msg: NSLocalizedString("app.done", comment: ""))
                            })
                            Button("account.action.delete", role: .destructive, action: deleteAccount)
                        }
                    }
                }
                .formStyle(.grouped)
            }
        }
        .alert(
            mate.title,
            isPresented: $mate.showIt,
            actions: {},
            message: { Text(mate.msg) }
        )
    }
    
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

fileprivate struct AccountTile: View {
    let account: HoyoAccount
    
    var body: some View {
        HStack {
            KFImage(URL(string: account.bbsHeadImg))
                .placeholder({ ProgressView() })
                .loadDiskFileSynchronously(true)
                .resizable()
                .frame(width: 32, height: 32)
                .clipShape(.circle)
                .padding(.trailing)
            Text(account.bbsNicname).bold()
        }
    }
}

fileprivate struct LoginPane: View {
    @Environment(\.modelContext) private var operate
    @StateObject private var viewModel = AccountViewModel()
    let currentAccounts: [HoyoAccount]
    let dismissIt: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("account.login.title").font(.title2.bold()).padding(.top)
            Image(nsImage: viewModel.uiState.qrcode ?? NSImage(size: NSSize(width: 200, height: 200)))
                .resizable().scaledToFit()
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .onAppear {
                    Task.detached {
                        await viewModel.fetchImage()
                    }
                }
                .onTapGesture { // 点按刷新二维码
                    viewModel.uiState.qrcode = nil
                    Task.detached {
                        await viewModel.fetchImage()
                    }
                }
            Text("account.login.tip.login")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Button("account.login.action.confirm", action: {
                viewModel.login(accounts: currentAccounts) { loginedAccount in
                    DispatchQueue.main.async {
                        self.operate.insert(loginedAccount)
                        try! self.operate.save()
                        self.dismissIt()
                    }
                }
            }).buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.thinMaterial)
        .presentationDetents([.medium, .large])
        .alert(
            viewModel.uiState.loginAlert.title,
            isPresented: $viewModel.uiState.loginAlert.showIt,
            actions: {},
            message: { Text(viewModel.uiState.loginAlert.msg) }
        )
    }
}
