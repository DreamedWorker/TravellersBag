//
//  AccountScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/1.
//

import SwiftUI
import Kingfisher
import AlertToast

struct AccountScreen: View {
    @StateObject private var model: AccountViewModel = AccountViewModel()
    @State private var selectedAccount: MihoyoAccount? = nil
    
    var body: some View {
        NavigationStack {
            HSplitView {
                VStack {
                    List(selection: $selectedAccount) {
                        ForEach(model.accounts){ account in
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
                }.frame(minWidth: 150, maxWidth: 170, maxHeight: .infinity)
                VStack {
                    if let account = selectedAccount {
                        AccountDetail(
                            setDefaultAccount: { model.setDefault(account: account) },
                            logout: { selected in model.logoutFunc(account: selected) },
                            checkState: { selected in Task { await model.checkAccountState(account: selected) } },
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
                }.frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(Text("home.sidebar.account"))
        .toolbar {
            ToolbarItem {
                Button(
                    action: { model.showAddType = true },
                    label: { Image(systemName: "person.crop.circle.badge.plus") }
                ).help("account.side.add")
            }
        }
        .alert(
            "account.side.addP", isPresented: $model.showAddType,
            actions: {
                Button("account.side.loginByQr", role: nil, action: {
                    model.showAddType = false
                    Task { await model.getQrAndShowWindow() }
                })
                Button("account.side.loginByCookie", action: {})
                Button("app.cancel", role: .cancel, action: { model.showAddType = false })
            },
            message: { Text("account.side.addP2") }
        )
        .sheet(isPresented: $model.loginByQr, content: { LoginByQr })
        .alert(model.alertMate.msg, isPresented: $model.alertMate.showIt, actions: {})
        .onAppear { model.getLocalAccounts() }
    }
    
    var LoginByQr: some View {
        return NavigationStack {
            Text("account.side.loginByQr").font(.title).bold()
            Image(nsImage: model.loginQRCode ?? NSImage()).resizable().frame(width: 128, height: 128)
            ZStack {}.frame(height: 16)
            Text("account.qr.tip").font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .confirmationAction, content: {
                Button("app.confirm", action: { Task { await model.queryStatusAndLogin() } })
            })
            ToolbarItem(placement: .cancellationAction, content: {
                Button("app.cancel", action: { model.loginByQr = false; model.loginQRCode = nil })
            })
            ToolbarItem(placement: .automatic, content: {
                Button("account.qr.refresh", action: {
                    Task { await model.getQrAndShowWindow() }
                } )
            })
        }
    }
}

private struct AccountDetail: View {
    let setDefaultAccount: () -> Void
    let logout: (MihoyoAccount) -> Void
    let checkState: (MihoyoAccount) -> Void
    @State private var showLogout = false
    @State private var silenceToast = false
    let account: MihoyoAccount
    
    var body: some View {
        ScrollView {
            KFImage(URL(string: account.misheHead))
                .placeholder({ ProgressView() })
                .loadDiskFileSynchronously(true)
                .resizable()
                .frame(width: 96, height: 96)
                .aspectRatio(contentMode: .fill)
                .clipShape(Circle())
                .padding(.top, 16)
            Text(account.misheNicname).font(.title2).bold()
            Text(account.gameInfo.serverName).bold().padding(.bottom, 4)
            Group(content: {
                VStack(spacing: 8) {
                    Form {
                        HStack(spacing: 8, content: {
                            Image(systemName: "person.text.rectangle")
                            Text("account.detail.game_uid")
                            Spacer()
                            Text(account.gameInfo.genshinUID).foregroundStyle(.secondary)
                        })
                        HStack(spacing: 8, content: {
                            Image(systemName: "tag")
                            Text("account.detail.genshin_name")
                            Spacer()
                            Text(account.gameInfo.genshinNicname).foregroundStyle(.secondary)
                        })
                        HStack(spacing: 8, content: {
                            Image(systemName: "level")
                            Text("account.detail.genshin_level")
                            Spacer()
                            Text(account.gameInfo.level).foregroundStyle(.secondary)
                        })
                        HStack(spacing: 8, content: {
                            Image(systemName: "person.text.rectangle")
                            Text("account.detail.shequ_uid")
                            Spacer()
                            Text(account.cookies.stuid).foregroundStyle(.secondary)
                        })
                        HStack(spacing: 8, content: {
                            Image(systemName: "ellipsis.rectangle")
                            Text("account.detail.shequ_mid")
                            Spacer()
                            Text(account.cookies.mid).foregroundStyle(.secondary)
                        })
                        HStack {
                            Spacer()
                            Button("account.detail.def_account", action: { setDefaultAccount() })
                        }
                    }.formStyle(.grouped)
                }
            })
            HStack {
                Button("account.detail.logout", role: .destructive, action: { showLogout = true })
                Spacer()
                Button("account.detail.copy_cookie", action: {
                    let context = "stuid=\(account.cookies.stuid);stoken=\(account.cookies.stoken);mid=\(account.cookies.mid)"
                    let board = NSPasteboard.general
                    board.clearContents()
                    board.setData(context.data(using: .utf8), forType: .string)
                    silenceToast = true
                })
                Button("account.detail.connect", action: { checkState(account) })
            }.padding(.horizontal, 16).padding(.bottom, 8)
        }
        .alert(
            "account.alert.logout", isPresented: $showLogout,
            actions: {
                Button("app.confirm", role: .destructive, action: {
                    showLogout = false; logout(account)
                })
                Button("app.cancel", role: .cancel, action: { showLogout = false })
            },
            message: { Text("account.alert.logoutM") }
        )
        .toast(isPresenting: $silenceToast, alert: { AlertToast(displayMode: .alert, type: .complete(.green)) })
    }
}
