//
//  CharacterScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/17.
//

import SwiftUI
import Kingfisher

struct CharacterScreen: View {
    @Environment(\.managedObjectContext) private var dataManager
    @StateObject private var viewModel = CharacterModel.shared
    
    var body: some View {
        VStack {
            if HomeController.shared.currentUser != nil {
                switch viewModel.uiState {
                case .Loading:
                    VStack {
                        Image(systemName: "clock.badge").font(.system(size: 32))
                    }.onAppear { viewModel.showCharacters(uid: HomeController.shared.currentUser!.genshinUID!) }
                case .Succeed:
                    HSplitView(content: {
                        List(selection: $viewModel.characterDetail) {
                            ForEach(viewModel.characterShowing, id: \.avatarId){ single in
                                NavigationLink(
                                    value: single,
                                    label: { Label(
                                        title: {
                                            Text(viewModel.getTranslationText(key: single.avatarId))
                                                .padding(.leading, 8)
                                        },
                                        icon: {
                                            KFImage(URL(string: viewModel.getCharacterIcon(key: single.avatarId))!)
                                                .placeholder({ Image(systemName: "dot.radiowaves.left.and.right") })
                                                .loadDiskFileSynchronously()
                                                .resizable()
                                                .frame(width: 32, height: 32)
                                                .aspectRatio(contentMode: .fill)
                                                .clipShape(Circle())
                                        }
                                    )
                                    })
                            }
                        }.frame(minWidth: 120, maxWidth: 150).listStyle(.inset)
                        CharacterDetail(character: viewModel.characterDetail)
                            .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                    })
                case .Failed:
                    VStack {
                        Image(systemName: "person.crop.circle.badge.exclamationmark").font(.system(size: 32))
                    }
                }
            } else {
                noDefaultUser
            }
        }
        .navigationTitle(Text("home.sider.characters"))
        .toolbar {
            ToolbarItem(content: {
                Button(action: {}, label: { Image(systemName: "figure.stand").help("character.toolbar.verify") })
            })
            ToolbarItem(content: {
                Button(action: {
                    viewModel.showUpdateWindow = true
                }, label: { Image(systemName: "arrow.triangle.2.circlepath").help("character.toolbar.sync") })
            })
        }
        .sheet(isPresented: $viewModel.showUpdateWindow, content: { updateDataScouceChoice })
    }
    
    var updateDataScouceChoice: some View {
        NavigationStack {
            VStack {
                Text("character.sheet_update.title").font(.title2).bold()
                    .padding(.bottom, 8)
                List {
                    MDLikeTile(
                        leadingIcon: "network", endIcon: "arrow.forward",
                        title: NSLocalizedString("character.sheet_update.enka", comment: ""),
                        onClick: {
                            viewModel.uiState = .Loading
                            viewModel.characterDetail = nil
                            Task {
                                let uid = HomeController.shared.currentUser!.genshinUID!
                                await viewModel.updateCharactersFromEnka(uid: uid)
                            }
                        }
                    )
                    MDLikeTile(
                        leadingIcon: "network.badge.shield.half.filled",
                        endIcon: "arrow.forward", title: NSLocalizedString("character.sheet_update.miyoushe", comment: ""),
                        onClick: {}
                    )
                }
            }.padding()
        }
        .frame(minWidth: 400, minHeight: 300)
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("app.cancel", action: {
                    viewModel.showUpdateWindow = false
                }).buttonStyle(BorderedProminentButtonStyle())
            })
        })
    }
    
    var noDefaultUser: some View {
        VStack {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 32)).foregroundStyle(.accent)
            Text("character.forbid.no_user").padding(.vertical, 8)
                .font(.title3).bold()
            Button("character.forbid.rerfresh", action: { HomeController.shared.refreshLoginState() })
                .buttonStyle(BorderedProminentButtonStyle())
        }.padding()
    }
}

#Preview {
    CharacterScreen()
}
