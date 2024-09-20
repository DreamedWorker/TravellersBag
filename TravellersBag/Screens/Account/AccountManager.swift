//
//  AccountManager.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/16.
//

import SwiftUI

struct AccountManager: View {
    @Environment(\.managedObjectContext) private var dataManager
    @StateObject private var viewModel = AccountModel()
    @State var selectedAccount: ShequAccount? = nil
    @State var cookies: String = ""
    
    var body: some View {
        NavigationStack {
            HSplitView {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        HStack {
                            Button(action: {
                                Task { await viewModel.fetchQrCode() }
                            }, label: { Image(systemName: "qrcode").help("account.login.by_qr") })
                            Button(action: {
                                viewModel.showCookieLogin = true
                            }, label: { Image(systemName: "ellipsis.rectangle").help("account.login.by_cookie") })
                        }
                    }.padding(.leading, 8).padding(.top, 8)
                    NavigationLink("account.login.hutao", destination: { HutaoPassport() }).padding(.leading, 8)
                    Divider().padding(.horizontal, 4).padding(.vertical, 2)
                    List(selection: $selectedAccount) {
                        ForEach(viewModel.signedAccount){ account in
                            Label(account.shequNicname!, systemImage: "person.crop.circle").tag(account)
                        }
                    }
                }
                .background(BackgroundStyle())
                .frame(minWidth: 130, maxWidth: 150)
                VStack {
                    if selectedAccount == nil {
                        CardView {
                            VStack {
                                Image("expecting_but_nothing").resizable().scaledToFit()
                                    .frame(width: 72, height: 72).padding(.bottom, 4)
                                Text("account.detail.select_first").font(.title3).bold()
                            }.padding()
                        }.frame(maxWidth: 450)
                    } else {
                        AccountDetail(
                            account: selectedAccount!,
                            setDefaultAccount: {
                                UserDefaultHelper.shared.setValue(forKey: "defaultAccount", value: selectedAccount!.genshinUID!)
                                GlobalUIModel.exported.makeAnAlert(type: 1, msg: "操作完成")
                            },
                            logout: {
                                if UserDefaultHelper.shared.getValue(forKey: "defaultAccount", def: "无") == selectedAccount!.genshinUID {
                                    UserDefaultHelper.shared.setValue(forKey: "defaultAccount", value: "无")
                                }
                                CoreDataHelper.shared.deleteUser(single: selectedAccount!)
                                selectedAccount = nil
                                viewModel.fetchUsers()
                                GlobalUIModel.exported.makeAnAlert(type: 1, msg: "操作完成")
                            }
                        )
                    }
                }.frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(Text("home.sider.account"))
            .onAppear {
                viewModel.initSomething(dataManager: dataManager)
            }
            .sheet(isPresented: $viewModel.qrLogin.showIt, content: { LoginByQrCode })
            .sheet(isPresented: $viewModel.showCookieLogin, content: { LoginByCookie })
        }
    }
    
    var LoginByQrCode: some View {
        return NavigationStack {
            VStack {
                Text("account.qr.title").font(.title2).bold().padding(.bottom, 8)
                Image(nsImage: viewModel.qrCode)
                    .scaledToFill()
                    .frame(width: 250, height: 250)
                    .aspectRatio(contentMode: .fill)
                    .padding(.bottom, 4)
                HStack {
                    Button("account.qr.refresh_one", action: {
                        Task { await viewModel.fetchQrCode(isRefresh: true) }
                    })
                    Spacer()
                }
            }.padding()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("app.cancel", action: { viewModel.cancelLoginByQr() })
            })
            ToolbarItem(placement: .confirmationAction, content: {
                Button("account.qr.finish", action: {
                    Task { await viewModel.queryQrCode() }
                })
            })
        }
    }
    
    var LoginByCookie: some View {
        return NavigationStack {
            Text("account.cookie.title").font(.title2).bold()
            VStack(alignment: .leading) {
                TextField("account.cookie.hint", text: $cookies).padding(.top, 16)
                Text("account.cookie.helper").font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("app.cancel", action: { viewModel.showCookieLogin = false; cookies = "" })
            })
            ToolbarItem(placement: .confirmationAction, content: {
                Button("app.confirm", action: {
                    Task {
                        await viewModel.checkCookieContent(cookieInput: cookies, clean: {
                            cookies = ""
                            viewModel.showCookieLogin = false
                        })
                    }
                })
            })
        }
    }
}
