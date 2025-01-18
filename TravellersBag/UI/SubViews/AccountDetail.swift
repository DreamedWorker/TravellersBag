//
//  AccountDetail.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/10.
//

import SwiftUI
import Kingfisher

extension AccountView {
    struct AccountDetail: View {
        let setDefaultAccount: () -> Void
        let logout: (MihoyoAccount) -> Void
        let checkState: (MihoyoAccount) -> Void
        @State private var showLogout = false
        @State private var silenceToast = false
        let account: MihoyoAccount
        var body: some View {
            LazyVStack {
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
                    Button("def.confirm", role: .destructive, action: {
                        showLogout = false; logout(account)
                    })
                    Button("def.cancel", role: .cancel, action: { showLogout = false })
                },
                message: { Text("account.alert.logoutM") }
            )
            .alert("def.operationSuccessful", isPresented: $silenceToast, actions: {})
        }
    }
}
