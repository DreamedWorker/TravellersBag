//
//  AddNewNote.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/12/1.
//

import SwiftUI

extension DailyNoteScreen {
    struct AddNewNote: View {
        var accounts: [MihoyoAccount]
        var dismiss: () -> Void
        var addIt: (MihoyoAccount) -> Void
        
        var body: some View {
            NavigationStack {
                Text("daily.add.title").font(.title).bold()
                
                Form {
                    ForEach(accounts) { account in
                        HStack {
                            Label(account.gameInfo.genshinNicname, systemImage: "person.fill")
                            Spacer()
                            Button("daily.add.fetch", action: {
                                addIt(account)
                            }).buttonStyle(BorderedProminentButtonStyle())
                        }
                    }
                }.formStyle(.grouped)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button("app.cancel", action: dismiss)
                })
            }
        }
    }
}
