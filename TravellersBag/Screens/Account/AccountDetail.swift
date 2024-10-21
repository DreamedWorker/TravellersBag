//
//  AccountDetail.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/17.
//

import SwiftUI
import Kingfisher
import AppKit

struct AccountDetail: View {
    let account: ShequAccount
    private var imgAddress: String
    let setDefaultAccount: () -> Void
    let logout: () -> Void
    
    @State private var showLogout = false
    @State var showEverything = true
    
    init(
        account: ShequAccount,
        setDefaultAccount: @escaping () -> Void,
        logout: @escaping () -> Void
    ) {
        self.account = account
        self.imgAddress = HoyoResKit.default.getCharacterHeadAddress(key: account.genshinPicID!)
        self.setDefaultAccount = setDefaultAccount
        self.logout = logout
    }
    
    var body: some View {
        if showEverything {
            ScrollView {
                VStack {
                    KFImage(URL(string: account.shequHead!))
                        .placeholder({ Image(systemName: "wifi").symbolRenderingMode(.multicolor) })
                        .loadDiskFileSynchronously(true)
                        .resizable()
                        .frame(width: 96, height: 96)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .padding(.top, 16)
                    Text(account.shequNicname!).font(.title2).bold().padding(.bottom, 16)
                    GroupBox("account.detail.tab_genshin") {
                        HStack(spacing: 8, content: {
                            Image(systemName: "person.text.rectangle")
                            Text("account.detail.genshin_uid")
                            Spacer()
                            Text(account.genshinUID!).foregroundStyle(.secondary)
                        }).padding(4)
                        HStack(spacing: 8, content: {
                            Image(systemName: "tag")
                            Text("account.detail.genshin_name")
                            Spacer()
                            Text(account.genshinNicname!).foregroundStyle(.secondary)
                        }).padding(4)
                        HStack(spacing: 8, content: {
                            Image(systemName: "person.circle")
                            Text("account.detail.genshin_head")
                            Spacer()
                            if String(imgAddress.split(separator: "@")[0]) == "C"  {
                                KFImage(URL(string: String(imgAddress.split(separator: "@")[1])))
                                    .placeholder({ Image(systemName: "wifi").symbolRenderingMode(.multicolor) })
                                    .loadDiskFileSynchronously(true)
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .aspectRatio(contentMode: .fill)
                                    .clipShape(Circle())
                            } else {
                                Image(nsImage: NSImage(contentsOfFile: String(imgAddress.split(separator: "@")[1]))!)
                                    .resizable().scaledToFill().frame(width: 24, height: 24).aspectRatio(contentMode: .fill).clipShape(Circle())
                            }
                        }).padding(4)
                        HStack(spacing: 8, content: {
                            Image(systemName: "level")
                            Text("account.detail.genshin_level")
                            Spacer()
                            Text(account.level!).foregroundStyle(.secondary)
                        }).padding(4)
                        HStack {
                            Spacer()
                            Button("account.detail.connect", action: {})
                        }.padding(4)
                    }.padding(.bottom, 8)
                    GroupBox("account.detail.tab_shequ") {
                        HStack(spacing: 8, content: {
                            Image(systemName: "person.text.rectangle")
                            Text("account.detail.shequ_uid")
                            Spacer()
                            Text(account.stuid!).foregroundStyle(.secondary)
                        }).padding(4)
                        HStack(spacing: 8, content: {
                            Image(systemName: "ellipsis.rectangle")
                            Text("account.detail.shequ_mid")
                            Spacer()
                            Text(account.mid!).foregroundStyle(.secondary)
                        }).padding(4)
                    }.padding(.bottom, 8)
                    HStack {
                        Button("account.detail.logout", action: { showLogout = true })
                        Spacer()
                        Button("account.detail.copy_cookie", action: {
                            let context = "stuid=\(account.stuid!);stoken=\(account.stoken!);mid=\(account.mid!)"
                            let board = NSPasteboard.general
                            board.clearContents()
                            board.setData(context.data(using: .utf8), forType: .string)
                            GlobalUIModel.exported.makeAnAlert(type: 1, msg: "操作完成")
                        })
                        Button("account.detail.def_account", action: setDefaultAccount)
                    }.padding(.horizontal).padding(.bottom, 16)
                }
                .padding(.horizontal, 16)
            }
            .alert(
                "app.warning", isPresented: $showLogout,
                actions: {
                    Button("app.cancel", action: { showLogout = false })
                    Button(
                        action: { showLogout = false; showEverything = false ;logout() },
                        label: { Text("app.confirm").foregroundStyle(.red) }
                    )
                },
                message: { Text("account.detail.logout_p") }
            )
        }
    }
}
