//
//  DailyNoteView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/12.
//

import SwiftUI
import SwiftData

struct DailyNoteView: View {
    @StateObject private var vm = DailyNoteViewModel()
    @Environment(\.modelContext) private var mc
    @Query private var mihoyoAccounts: [MihoyoAccount]
    @State private var showAddSheet: Bool = false
    
    init() {
        let groupDailyNoteRoot = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "NV65B8VFUD.TravellersBag")!
            .appending(component: "NoteWidgets").appending(component: "AllowedList")
        if !FileManager.default.fileExists(atPath: groupDailyNoteRoot.toStringPath()) {
            try! FileManager.default.createDirectory(at: groupDailyNoteRoot, withIntermediateDirectories: true)
        }
    }
    
    var body: some View {
        NavigationStack {
            if vm.shouldShowContent {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(vm.notes) { note in
                            if let thisAct = mihoyoAccounts.filter({ $0.gameInfo.genshinUID == note.id }).first {
                                if let noteContent = note.content {
                                    NoteCell(
                                        dailyContext: noteContent,
                                        account: thisAct,
                                        deleteEvt: { vm.deleteNote(note: note) },
                                        refreshEvt: {
                                            Task {
                                                await vm.fetchDailyNote(account: thisAct)
                                                vm.alertMate.showAlert(msg: NSLocalizedString("def.operationSuccessful", comment: ""))
                                            }
                                        }
                                    )
                                } else {
                                    AbnormalPane(delete: { vm.deleteNote(note: note) })
                                }
                            } else {
                                AbnormalPane(delete: { vm.deleteNote(note: note) })
                            }
                        }
                    }
                    .padding(8)
                }
            } else {
                DefaultPane
                    .onAppear {
                        vm.getSomething()
                    }
            }
        }
        .alert(vm.alertMate.msg, isPresented: $vm.alertMate.showIt, actions: {})
        .navigationTitle(Text("home.sidebar.note"))
        .toolbar {
            ToolbarItem {
                Button(action: { showAddSheet = true }, label: { Image(systemName: "plus") })
            }
        }
        .sheet(
            isPresented: $showAddSheet,
            content: {
                AddNewNote(
                    accounts: mihoyoAccounts,
                    dismiss: { showAddSheet = false },
                    addIt: { act in
                        showAddSheet = false
                        Task { await vm.addNewNote2Local(account: act) }
                    })
            }
        )
    }
    
    private var DefaultPane: some View {
        return VStack {
            Image("dailynote_empty").resizable().frame(width: 72, height: 72)
            Text("daily.empty").font(.title2).bold()
            Button(
                action: {
                    if let account = mihoyoAccounts.filter({ $0.active == true }).first {
                        Task { await vm.fetchDailyNote(account: account) }
                    } else {
                        vm.alertMate.showAlert(msg: NSLocalizedString("daily.error.needDefaultAccountFirst", comment: ""))
                    }
                },
                label: {
                    Label("daily.empty.createFromDef", systemImage: "note.text.badge.plus").padding()
                }
            ).padding(.top, 16)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
    }
}

#Preview {
    DailyNoteView()
}
