//
//  AccountScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/16.
//

import SwiftUI

struct AccountScreen: View {
    @Environment(\.managedObjectContext) private var dataContext
    @StateObject private var viewModel = AccountModel.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                //功能区
                Form {
                    NavigationLink(
                        destination: { HutaoAccountScreen() },
                        label: { Label(
                            title: { Text("user.feat.hutao") },
                            icon: { Image(systemName: "wallet.pass") }
                        )}
                    )
                }.formStyle(.grouped).scrollDisabled(true)
                // 这里展示米游社账号
                Form {
                    HStack {
                        Text("user.table_mishe.title").font(.title2).bold()
                            .padding(.trailing, 8)
                        Spacer()
                    }
                    ForEach(viewModel.accounts){ account in
                        AccountTile(
                            account: account,
                            refresh: { viewModel.fetchAccounts() },
                            checkIn: {}
                        )
                    }
                }.formStyle(.grouped).scrollDisabled(true)
                    .padding(.bottom, 8)
                // 这里展示对应的原神账号
                Form {
                    HStack {
                        Text("user.table_hk4e.title").font(.title2).bold()
                            .padding(.trailing, 8)
                        Text("user.table_hk4e.sub").font(.callout)
                        Spacer()
                    }
                    ForEach(viewModel.accounts){ account in
                        AccountTile(
                            account: account,
                            showSub: true,
                            refresh: {},
                            checkIn: {},
                            genshinUrl: viewModel.getGenshinHeadUrl(id: account.genshinPicID!)
                        )
                    }
                }.formStyle(.grouped).scrollDisabled(true)
            }
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
                        label: { Image(systemName: "qrcode").help("user.add.by_qr") }
                    )
                })
                ToolbarItem(content: {
                    Button(
                        action: { viewModel.showCookieWindow = true },
                        label: { Image(systemName: "square.and.pencil").help("user.add.by_cookie") }
                    )
                })
            })
            .onAppear {
                viewModel.initSomething(inContext: dataContext)
            }
            .sheet(isPresented: $viewModel.showQRCodeWindow, content: { loginByQRcode })
            .sheet(isPresented: $viewModel.showCookieWindow, content: { loginByCookie })
    }
    
    var loginByQRcode: some View {
        VStack {
            Text("user.qr.title")
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
                Button("user.qr.refresh", action: {
                    viewModel.cancelOp()
                    Task { await viewModel.fetchQRCode() }
                })
            }.padding(.bottom, 2)
            Button("user.qr.finished", action: {
                Task {
                    await viewModel.queryQRState() // 本方法集查询状态和获取登录信息为一体 完成后自动关闭弹窗并更新列表
                }
            }).padding(.bottom, 2)
            // 没错 懒 直接贴出来 没有消息的时候反正也看不到
            Text(viewModel.qrScanState).foregroundStyle(Color.red)
        }
        .padding() // 不再允许轮询 需要手动确认完成扫码
    }
    
    var loginByCookie: some View {
        VStack {
            Text("user.cookie.title")
                .font(.title2).bold()
                .padding(.bottom, 8)
            TextField(
                text: $viewModel.cookieInput,
                label: { Label("user.cookie.input_label", systemImage: "key.viewfinder") }
            ).padding(.bottom, 2).frame(maxWidth: 460)
            HStack {
                Text("user.cookie.input_helper").font(.footnote)
                Spacer()
            }
            ZStack {} // 占位用的 让窗口大小看起来合理
                .background(Color.clear)
                .frame(width: 1, height: 120)
            HStack {
                Button("app.cancel", action: {
                    viewModel.cookieInput = ""
                    viewModel.showCookieWindow = false
                }).padding(.trailing, 2)
                Button("app.confirm", action: {
                    Task {
                        await viewModel.checkCookieContent()
                    }
                })
            }.padding(.bottom, 2)
            Text(viewModel.qrScanState).foregroundStyle(Color.red)
        }.padding()
    }
}

#Preview {
    AccountScreen()
}
