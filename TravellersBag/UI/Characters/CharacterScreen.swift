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
        VStack {
            Text("app.name")
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
                    print("来自前端的返回数据:\(con)")
                    Task {
                        await viewModel.verifyGeetestCode(validate: con)
                    }
                }).frame(width: 600, height: 400)
            }
        })
        .toast(isPresenting: $viewModel.showError, alert: { AlertToast(type: .error(.red), title: viewModel.errMsg) })
    }
}

#Preview {
    CharacterScreen()
}
