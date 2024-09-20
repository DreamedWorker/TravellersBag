//
//  HutaoPassport.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/18.
//

import SwiftUI

struct HutaoPassport : View {
    @Environment(\.managedObjectContext) private var dm
    @StateObject private var viewModel = PassportModel()
    
    var body: some View {
        ScrollView {
            if viewModel.hasAccount {
                VStack {
                    Image("libhutaokit_no_account")
                        .resizable().scaledToFit()
                        .frame(width: 96, height: 96)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .padding(.top, 16)
                    Text(viewModel.myHutaoAccount?.userName ?? "").font(.title2).bold().padding(.bottom, 16)
                    Form {
                        HStack(spacing: 16) {
                            Image(systemName: "timer")
                            Text("hutao.main.table_expire")
                            Spacer()
                            Text(viewModel.myHutaoAccount?.gachaLogExpireAt ?? "").foregroundStyle(.secondary)
                        }
                        HStack(spacing: 16) {
                            Image(systemName: "keyboard.onehanded.left")
                            Text("hutao.main.table_developer")
                            Spacer()
                            Text(viewModel.checkDeveloper()).foregroundStyle(.secondary)
                        }
                    }.formStyle(.grouped).scrollDisabled(true)
                    Form {
                        HStack(spacing: 16) {
                            Image(systemName: "menubar.dock.rectangle.badge.record")
                            Text("hutao.main.gacha")
                            Spacer()
                            Image(systemName: "arrow.forward").foregroundStyle(.secondary)
                        }.onTapGesture {
                            //
                            print("yes")
                        }
                    }.formStyle(.grouped).scrollDisabled(true)
                }
            } else {
                LoginPane
            }
        }
        .navigationTitle(Text("account.login.hutao"))
        .onAppear {
            viewModel.initSomething(dm: dm)
        }
        .sheet(isPresented: $viewModel.showLogin, content: { LoginSheet })
        .toolbar {
            ToolbarItem {
                Button(
                    action: { viewModel.removeAccount() },
                    label: { Image(systemName: "rectangle.portrait.and.arrow.right").help("hutao.logout") }
                )
            }
        }
    }
    
    var LoginSheet: some View {
        return NavigationStack {
            Text("hutao.passport.login_sheet_title").font(.title).bold().padding(.bottom, 8)
            VStack(alignment: .leading) {
                TextField("hutao.passport.login_sheet_email", text: $viewModel.loginInfo.email)
                SecureField("hutao.passport.login_sheet_password", text: $viewModel.loginInfo.password)
                Text("hutao.passport.login_sheet_agree").font(.callout).foregroundStyle(.secondary).padding(.top, 4)
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("app.cancel", action: { viewModel.showLogin = false })
            })
            ToolbarItem(placement: .confirmationAction, content: {
                Button("app.confirm", action: {
                    Task { await viewModel.tryLogin() }
                })
            })
        }
        .onDisappear { viewModel.loginInfo.clearAll() }
    }
    
    var LoginPane: some View {
        return VStack {
            Image("libhutaokit_no_account").resizable().scaledToFit().frame(width: 72, height: 72)
            Text("hutao.passport.login").font(.title2).bold().padding(.top, 8)
            Button("hutao.passport.login_btn", action: { viewModel.showLogin = true })
                .buttonStyle(BorderedProminentButtonStyle())
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
        .frame(maxWidth: 400)
    }
}
