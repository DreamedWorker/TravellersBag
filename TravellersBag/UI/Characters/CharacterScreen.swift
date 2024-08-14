//
//  CharacterScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/13.
//

import SwiftUI
import AlertToast

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
                        onClick: {}
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
            }
        }
        .toolbar(content: {
            ToolbarItem(content: {
                Button(
                    action: {
                        Task {
                            await viewModel.showWebOrNot()
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
                            try await CharacterService.shared.getAllCharacterFromMiyoushe(user: viewModel.currentUser!)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }).frame(width: 600, height: 400)
            }
        })
        .toast(isPresenting: $viewModel.showError, alert: { AlertToast(type: .error(.red), title: viewModel.errMsg) })
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
