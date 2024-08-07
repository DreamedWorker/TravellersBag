//
//  AccountManagerScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/6.
//

import SwiftUI
import CoreData
import AlertToast
import Kingfisher

struct AccountManagerScreen: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel = AccountManagerModel()
    
    var body: some View {
        ScrollView {
            Form {
                HStack {
                    Text("account.table_mishe.title").font(.title2).bold()
                        .padding(.trailing, 8)
                    Text("account.table_mishe.sub").font(.callout)
                    Spacer()
                }
                ForEach(viewModel.accountsHoyo){ account in
                    AccountTile(
                        account: account,
                        refresh: { viewModel.fetchAccounts() },
                        checkIn: {
                            Task {
                                await viewModel.updateGameData(user: account)
                            }
                        }
                    )
                }
            }.formStyle(.grouped).scrollDisabled(true)
        }
            .navigationTitle(Text("home.sider.account"))
            .toolbar(content: {
                ToolbarItem(content: {
                    Button(
                        action: {
                            Task {
                                await viewModel.fetchQRCode()
                                DispatchQueue.main.async {
                                    viewModel.showQRCodeWindow = true
                                }
                            }
                        },
                        label: { Image(systemName: "qrcode").help("account.add.by_qr") }
                    )
                })
                ToolbarItem(content: {
                    Button(
                        action: {},
                        label: { Image(systemName: "square.and.pencil").help("account.add.by_cookie") }
                    )
                })
            })
            .onAppear {
                viewModel.context = context
                viewModel.fetchAccounts()
                viewModel.fetchGameAccounts()
            }
            .toast(isPresenting: $viewModel.showFetchFatalToast, alert: { AlertToast(type: .error(Color.red), title: viewModel.fatalInfo) })
            .sheet(isPresented: $viewModel.showQRCodeWindow, content: { qrcodeStage })
    }
    
    var qrcodeStage : some View {
        VStack {
            Text("account.qrcode.title")
                .font(.title2).bold()
                .padding(.bottom, 4)
            Image(nsImage: viewModel.qrCodeImg)
                .scaledToFill()
                .frame(width: 250, height: 250)
                .aspectRatio(contentMode: .fill)
            Divider()
            HStack {
                Button("app.cancel", action: {
                    viewModel.showQRCodeWindow = false
                    viewModel.cancelOp()
                }).padding(.trailing, 8)
                Button("account.qrcode.refresh", action: {
                    viewModel.cancelOp()
                    Task { await viewModel.fetchQRCode() }
                })
            }.padding(.bottom, 2)
            Button("account.qrcode.finished", action: {
                Task {
                    await viewModel.queryQRState() // 本方法集查询状态和获取登录信息为一体 完成后自动关闭弹窗并更新列表
                }
            }).padding(.bottom, 2)
            // 没错 懒 直接贴出来 没有消息的时候反正也看不到
            Text(viewModel.qrScanState).foregroundStyle(Color.red)
        }
        .padding() // 不再允许轮询 需要手动确认完成扫码
    }
}

private struct AccountTile : View {
    private let account: HoyoAccounts
    private let refresh: () -> Void
    private let checkIn: () -> Void
    
    init(account: HoyoAccounts, refresh: @escaping () -> Void, checkIn: @escaping () -> Void) {
        self.account = account
        self.refresh = refresh
        self.checkIn = checkIn
    }
    
    var body: some View {
        HStack {
            KFImage(URL(string: account.misheHead ?? ""))
                .placeholder({ Image(systemName: "dot.radiowaves.left.and.right") })
                .loadDiskFileSynchronously(true)
                .resizable()
                .frame(width: 32, height: 32)
                .aspectRatio(contentMode: .fill)
                .clipShape(Circle())
                .padding(.trailing, 8)
            Text(account.misheNicname ?? "请核验: \(account.mid!)").font(.headline)
            Spacer()
            Button("account.table_mishe.check_in", action: { checkIn() })
            Button("account.table_mishe.use_default", action: {
                LocalEnvironment.shared.setStringValue(key: "default_account_stuid", value: account.stuid!)
                LocalEnvironment.shared.setStringValue(key: "default_account_stoken", value: account.stoken!)
                LocalEnvironment.shared.setStringValue(key: "default_account_mid", value: account.mid!)
            })
            Button("account.table_mishe.delete", action: {
                LocalEnvironment.shared.setStringValue(key: "default_account_stuid", value: "")
                LocalEnvironment.shared.setStringValue(key: "default_account_stoken", value: "")
                LocalEnvironment.shared.setStringValue(key: "default_account_mid", value: "")
                let acc = account
                let _ = AppPersistence.shared.deleteUser(item: acc)
                let _ = AppPersistence.shared.save()
                refresh()
            })
        }.padding(4)
    }
}

#Preview {
    AccountManagerScreen()
}
