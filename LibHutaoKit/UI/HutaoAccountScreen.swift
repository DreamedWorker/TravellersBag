//
//  HutaoAccountScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/29.
//

import SwiftUI

struct HutaoAccountScreen: View {
    @Environment(\.managedObjectContext) private var dataManager
    @StateObject private var viewModel = HutaoAccountModel.shared
    
    var body: some View {
        VStack {
            if viewModel.showUI {
                ScrollView {
                    VStack {
                        HStack(spacing: 16) {
                            Image(systemName: "person").font(.title2)
                            Text("hutaokit.main.title").font(.title2).bold()
                            Spacer()
                            Button("hutaokit.main.logout", action: { viewModel.showLogoutAlert = true })
                        }.padding(.bottom, 8)
                        HStack(spacing: 16) {
                            Image(systemName: "timer")
                            Text("hutaokit.main.table_expire")
                            Spacer()
                            Text(viewModel.hutaoAccount!.gachaLogExpireAt!).foregroundStyle(.secondary)
                        }
                        Divider().padding(.leading, 16)
                        HStack(spacing: 16) {
                            Image(systemName: "keyboard.onehanded.left")
                            Text("hutaokit.main.table_developer")
                            Spacer()
                            Text((viewModel.hutaoAccount!.isLicensedDeveloper) ? "app.yes" : "app.no").foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                    Text("hutaokit.main.time_tip").font(.caption).multilineTextAlignment(.leading)
                }
                .padding(16)
                .alert(
                    "hutaokit.main.logout", isPresented: $viewModel.showLogoutAlert,
                    actions: {
                        Button("app.confirm", action: {
                            viewModel.showLogoutAlert = false
                            viewModel.removeAccount()
                        })
                        Button("app.cancel", action: { viewModel.showLogoutAlert = false })
                    },
                    message: { Text("hutaokit.main.logout_alert")}
                )
            } else {
                Image("libhutaokit_no_account")
                    .resizable().scaledToFit()
                    .frame(width: 72, height: 72)
                Text("hutaokit.no_account").font(.title2).bold()
            }
        }
        .navigationTitle(Text("hutaokit.title"))
        .onAppear {
            viewModel.initSomething(dm: dataManager)
        }
        .toolbar {
            ToolbarItem {
                Button(action: { viewModel.showLoginPane = true }, label: {
                    Image(systemName: "person.crop.circle.badge.plus").help("hutaokit.login")
                }).disabled(viewModel.showUI) // 如果显示UI内容 则说明有账号了，禁止登录
            }
        }
        .sheet(isPresented: $viewModel.showLoginPane, content: { loginPane })
    }
    
    var loginPane: some View {
        return NavigationStack {
            Text("hutaokit.login.title").font(.title).bold().padding(.bottom, 24)
            TextField(text: $viewModel.email, label: { Label("hutaokit.login.email", systemImage: "envelope.fill")})
                .textFieldStyle(.roundedBorder).padding(.bottom, 8)
            SecureField("hutaokit.login.password", text: $viewModel.password).textFieldStyle(.roundedBorder)
            Divider().padding(.vertical, 8)
            Text("hutaokit.login.tip").font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("app.cancel", action: { viewModel.showLoginPane = false })
            })
            ToolbarItem(placement: .confirmationAction, content: {
                Button("app.confirm", action: {
                    Task {
                        do {
                            try await viewModel.tryLogin()
                        } catch {
                            DispatchQueue.main.async {
                                self.viewModel.showLoginPane = false
                                HomeController.shared.showErrorDialog(
                                    msg: String.localizedStringWithFormat(
                                        NSLocalizedString("hutaokit.login.failed", comment: ""), error.localizedDescription)
                                )
                            }
                        }
                    }
                }).buttonStyle(BorderedProminentButtonStyle())
            })
        })
        .frame(minWidth: 550)
    }
}

#Preview {
    HutaoAccountScreen()
}
