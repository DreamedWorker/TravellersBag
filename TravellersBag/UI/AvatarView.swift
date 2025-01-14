//
//  AvatarView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/14.
//

import SwiftUI
import SwiftData
import Kingfisher

struct AvatarView: View {
    @Environment(\.modelContext) private var mc
    @Query private var accounts: [MihoyoAccount]
    @StateObject private var vm = AvatarViewModel()
    @State private var displayAccount: MihoyoAccount? = nil
    @State private var selectedAvatar: AvatarIntro? = nil
    
    var body: some View {
        NavigationStack {
            if displayAccount != nil {
                if vm.hasAccountData(uid: displayAccount!.gameInfo.genshinUID) {
                    if vm.showUI {
                        HSplitView {
                            List(selection: $selectedAvatar) {
                                ForEach(vm.avatarList) { avatar in
                                    HStack(spacing: 8, content: {
                                        KFImage(URL(string: avatar.sideIcon))
                                            .loadDiskFileSynchronously(true)
                                            .resizable()
                                            .frame(width: 36, height: 36)
                                        VStack(alignment: .leading, content: {
                                            Text(avatar.name)
                                            Text(
                                                String.localizedStringWithFormat(
                                                    NSLocalizedString("avatar.display.lv", comment: ""), String(avatar.level))
                                            ).font(.callout).foregroundStyle(.secondary)
                                        })
                                        Spacer()
                                    }).tag(avatar)
                                }
                            }.frame(minWidth: 150, maxWidth: 170)
                            VStack {
                                if let selected = selectedAvatar {
                                    AvatarDetail(
                                        intro: selected,
                                        detail: vm.getAvatarDetail(id: selected.id),
                                        getPropNameById: { it in return vm.getPropName(id: it) }
                                    )
                                } else {
                                    Text("avatar.display.select")
                                }
                            }.frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        Text("def.holding")
                            .padding()
                            .onAppear {
                                if vm.overview == nil || vm.detail == nil {
                                    Task { await vm.getOrRefresh(user: displayAccount!) }
                                }
                            }
                    }
                } else {
                    VStack {
                        Image("dailynote_empty").resizable().frame(width: 72, height: 72)
                        Text("avatar.empty.title").font(.title2).bold().padding(.bottom, 16)
                        Button(
                            action: {
                                Task { await vm.getOrRefresh(user: displayAccount!, useNetwork: true) }
                            },
                            label: { Text("avatar.empty.fetch").padding() }
                        )
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
                }
            } else {
                VStack {
                    Text("gacha.def.title").font(.title).bold()
                    Form {
                        ForEach(accounts) { account in
                            HStack {
                                Label(account.gameInfo.genshinUID, systemImage: "person.crop.circle")
                                Spacer()
                                Button("gacha.def.select", action: {
                                })
                            }
                        }
                    }
                }
                .onAppear {
                    if let def = accounts.filter({ $0.active == true }).first {
                        displayAccount = def
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
            }
        }
        .navigationTitle(Text("home.sidebar.avatar"))
        .alert(vm.alertMate.msg, isPresented: $vm.alertMate.showIt, actions: {})
    }
}

#Preview {
    AvatarView()
}
