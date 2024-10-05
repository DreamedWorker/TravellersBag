//
//  AvatarScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/2.
//

import SwiftUI
import Kingfisher

struct AvatarScreen: View {
    @StateObject private var viewModel = AvatarModel.shared
    @State private var showContext = GlobalUIModel.exported.hasDefAccount()
    @State private var selectedAvatar: AvatarIntro? = nil
    
    var body: some View {
        if showContext {
            if viewModel.showUI {
                HSplitView {
                    List(selection: $selectedAvatar) {
                        ForEach(viewModel.avatarList) { avatar in
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
                    }.frame(minWidth: 130, maxWidth: 150)
                    VStack {
                        if let selected = selectedAvatar {
                            AvatarDetail(
                                intro: selected,
                                detail: viewModel.getAvatarDetail(id: selected.id),
                                getPropNameById: { it in return viewModel.getPropName(id: it) }
                            )
                        } else {
                            Text("avatar.display.select")
                        }
                    }.frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                }
                .toolbar {
                    ToolbarItem {
                        Button(
                            action: {
                                if showContext {
                                    viewModel.showUI = false
                                    viewModel.overview = nil; viewModel.detail = nil
                                    Task { await viewModel.getOrRefresh() }
                                }
                            },
                            label: { Image(systemName: "arrow.clockwise") }
                        ).disabled(!viewModel.showUI)
                    }
                }
            } else {
                VStack {
                    Image("avatar_need_login").resizable().scaledToFit().frame(width: 72, height: 72).padding(.bottom, 8)
                    Text("avatar.no_data.title").font(.title2).bold()
                    Button("avatar.no_data.fetch", action: {
                        Task {
                            await viewModel.getOrRefresh()
                        }
                    }).buttonStyle(BorderedProminentButtonStyle())
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                .frame(minWidth: 400)
                .onAppear { viewModel.initSomething() }
            }
        } else {
            VStack {
                Image("avatar_need_login").resizable().scaledToFit().frame(width: 72, height: 72).padding(.bottom, 8)
                Text("daily.no_account.title").font(.title2).bold()
                Button("gacha.login_first", action: {
                    GlobalUIModel.exported.refreshDefAccount()
                    showContext = GlobalUIModel.exported.hasDefAccount()
                }).buttonStyle(BorderedProminentButtonStyle())
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
            .frame(minWidth: 400)
        }
    }
}
