//
//  DashboardView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/10.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()
    @Query private var allUsers: [MihoyoAccount]
    @State private var gameUID: String = ""
    @State private var selectAccount: Bool = false
    
    var body: some View {
        if vm.shouldShowContent {
            NavigationStack {
                DashboardBasicPart(
                    content: vm.basicData,
                    checkFileExist: { uid in
                        vm.shouldShowContent = false; vm.basicData = nil
                        let act = allUsers.filter({ $0.gameInfo.genshinUID == uid }).first!
                        Task { await vm.getSomething(account: act, useNetwork: true)}
                    },
                    gameUid: gameUID
                )
            }
            .navigationTitle(Text("home.sidebar.dashboard"))
            .toolbar {
                ToolbarItem {
                    Button(
                        action: { selectAccount = true },
                        label: { Image(systemName: "list.bullet.circle").help("dashboard.menu.another") }
                    )
                }
            }
            .sheet(isPresented: $selectAccount, content: { SelectOtherAccountsProfile })
        } else {
            VStack {
                Image("dashboard_empty").resizable().frame(width: 72, height: 72)
                Text("dashboard.waiting").font(.title2).bold()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
            .alert(vm.alertMate.msg, isPresented: $vm.alertMate.showIt, actions: {})
            .onAppear {
                if let defAccount = allUsers.filter({ $0.active == true }).first {
                    gameUID = defAccount.gameInfo.genshinUID
                    Task { await vm.getSomething(account: defAccount) }
                }
            }
        }
    }
    
    private var SelectOtherAccountsProfile: some View {
        return NavigationStack {
            Text("dashboard.more.title").font(.title).bold()
            Text("dashboard.more.description").multilineTextAlignment(.center)
            Form {
                ForEach(allUsers) { user in
                    HStack {
                        Label(user.gameInfo.genshinNicname, systemImage: "person.crop.circle")
                        Spacer()
                        Button("dashboard.more.choose", action: {
                            selectAccount = false; vm.shouldShowContent = false; vm.basicData = nil
                            Task { await vm.getSomething(account: user) }
                        }).buttonStyle(.borderless)
                    }
                }
            }.formStyle(.grouped)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("def.cancel", action: { selectAccount = false })
            })
        }
    }
}

#Preview {
    DashboardView()
}
