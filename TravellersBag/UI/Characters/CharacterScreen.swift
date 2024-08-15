//
//  CharacterScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/13.
//

import SwiftUI

struct CharacterScreen: View {
    @StateObject private var viewModel = CharacterModel()
    @Environment(\.managedObjectContext) private var managed
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Form { // 功能区
                    Text("character.table.title").font(.title2).bold()
                    SimpleTableItem(
                        title: NSLocalizedString("character.table.get_from_showcase", comment: ""),
                        sysImg: "macwindow.badge.plus",
                        onClick: {
                            if viewModel.currentUser != nil {
                                Task {
                                    do {
                                        try await viewModel.handleEnkaCharacters(uid: viewModel.currentUser!.genshinUID!)
                                    } catch {
                                        DispatchQueue.main.async {
                                            ContentMessager.shared.showErrorDialog(msg: "从橱窗加载角色数据失败，原因：\(error.localizedDescription)")
                                        }
                                    }
                                }
                            } else {
                                ContentMessager.shared.showErrorDialog(msg: "当前没有登录！")
                            }
                        }
                    )
                    SimpleTableItem(
                        title: NSLocalizedString("character.table.get_from_home", comment: ""),
                        sysImg: "iphone.homebutton.badge.play",
                        onClick: {}
                    )
                    Text("character.table.get_tip").font(.footnote)
                        .padding(.horizontal, 16)
                }.formStyle(.grouped)
                    .scrollDisabled(true)
                Form {
                    ForEach(viewModel.characters){ single in
                        Text(String(single.avatarID)).onTapGesture {
                            print(single)
                        }
                    }
                }
            }
        }
        .toolbar(content: {
            ToolbarItem(content: {
                Button(
                    action: {
                        Task {
                            await viewModel.showWebOrNot()
//                            let d = try await CharacterService.shared.pullCharactersFromEnka(gameUID: viewModel.currentUser!.genshinUID!)
//                            print(String(data: d, encoding: .utf8))
                        }
                    },
                    label: { Image(systemName: "barcode.viewfinder").help("character.toolbar.verify") }
                )
            })
        })
        .navigationTitle(Text("home.sider.characters"))
        .onAppear {
            viewModel.context = managed
            viewModel.fetchDefaultUser()
            viewModel.fetchCharacter()
        }
        .sheet(isPresented: $viewModel.showWeb, content: {
            VStack {
                HStack {
                    Button("app.cancel", action: { viewModel.showWeb = false }).padding()
                    Spacer()
                }
                Text("character.verify.window_title").font(.title)
                VerificationView(challenge: viewModel.challenge, gt: viewModel.gt, completion: {con in
                    Task {
                        await viewModel.verifyGeetestCode(validate: con)
                        do {
                            let _ = try await CharacterService.shared.getAllCharacterFromMiyoushe(user: viewModel.currentUser!)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }).frame(width: 600, height: 400)
            }
        })
    }
    
    private struct SimpleTableItem : View {
        let title: String
        let sysImg: String
        let onClick: () -> Void
        
        var body: some View {
            HStack {
                Label(title, systemImage: sysImg)
                Spacer()
                Image(systemName: "arrow.right")
            }.onTapGesture(perform: onClick)
        }
    }
}

#Preview {
    CharacterScreen()
}
