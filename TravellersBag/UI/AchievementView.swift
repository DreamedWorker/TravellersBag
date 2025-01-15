//
//  AchievementView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/14.
//

import SwiftUI
import SwiftData
import Kingfisher

struct AchievementView: View {
    @Environment(\.modelContext) private var mc
    @StateObject private var vm = AchievementViewModel()
    @State private var makeArchFile = MakeArchive()
    @State private var selected: AchieveList? = nil
    
    var body: some View {
        NavigationStack {
            if vm.achieveContent.isEmpty {
                VStack {
                    Image("home_waiting").resizable().scaledToFit().frame(width: 72, height: 72)
                    Text("achieve.no_archive.title").font(.title2).bold().padding(.vertical, 4)
                    Button("achieve.no_archive.make", action: { makeArchFile.showIt = true }).buttonStyle(BorderedProminentButtonStyle())
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                .onAppear {
                    vm.doInit(mc: mc)
                }
            } else {
                HSplitView {
                    List(selection: $selected) {
                        ForEach(vm.achieveList){ single in
                            AchieveGroupEntry(entry: single).tag(single)
                        }
                    }.frame(minWidth: 130, maxWidth: 150)
                    VStack {
                        if let checked = selected {
                            List {
                                ForEach(vm.achieveContent.filter({ $0.goal == checked.id }).sorted(by: { $0.id < $1.id })){ it in
                                    AchievementEntry(
                                        entry: it,
                                        changeState: { it1 in
                                            vm.changeAchieveState(item: it1, mc: mc)
                                        }
                                    )
                                }
                            }
                        }
                    }.frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                }
                .toolbar {
                    ToolbarItem {
                        if selected != nil {
                            SearchBar(
                                searchEvt: { it in
                                    vm.searchItems(mc: mc, keyWords: it, archive: vm.achieveContent.first!.archiveName)
                                },
                                clearResultEvt: {
                                    vm.clearResults(mc: mc, archive: vm.achieveContent.first!.archiveName)
                                }
                            )
                        }
                    }
                    ToolbarItem {
                        Button(
                            action: {
                                let panel = NSSavePanel()
                                panel.message = NSLocalizedString("gacha.home.menu.export_p", comment: "")
                                panel.allowedContentTypes = [.json]
                                panel.directoryURL = URL(string: NSHomeDirectory())
                                panel.canCreateDirectories = true
                                panel.begin { result in
                                    if result == NSApplication.ModalResponse.OK {
                                        do {
                                            try UIAF.shared.exportRecords(fileUrl: panel.url!, achieveContent: vm.achieveContent)
                                            vm.alertMate.showAlert(msg: NSLocalizedString("achieve.info.exportOK", comment: ""))
                                        } catch {
                                            vm.alertMate.showAlert(
                                                msg: String.localizedStringWithFormat(
                                                    NSLocalizedString("achieve.error.export", comment: ""),
                                                    error.localizedDescription)
                                            )
                                        }
                                    }
                                }
                            },
                            label: { Image(systemName: "square.and.arrow.up").help("gacha.home.menu.export") }
                        )
                    }
                    ToolbarItem {
                        Button(
                            action: {
                                let openPanel = NSOpenPanel()
                                openPanel.allowedContentTypes = [.json]; openPanel.allowsMultipleSelection = false
                                openPanel.message = NSLocalizedString("gacha.home.menu.update_p2", comment: "")
                                openPanel.begin { result in
                                    if result == NSApplication.ModalResponse.OK {
                                        if let url = openPanel.url {
                                            do {
                                                try UIAF.shared.updateRecords(fileUrl: url, mc: mc, archName: vm.achieveContent.first!.archiveName)
                                                vm.clearResults(mc: mc, archive: vm.achieveContent.first!.archiveName)
                                                vm.alertMate.showAlert(msg: NSLocalizedString("achieve.info.updateOK", comment: ""))
                                            } catch {
                                                vm.alertMate.showAlert(
                                                    msg: String.localizedStringWithFormat(
                                                        NSLocalizedString("achieve.error.update", comment: ""),
                                                        error.localizedDescription)
                                                )
                                            }
                                        }
                                    }
                                }
                            },
                            label: { Image(systemName: "square.and.arrow.down.on.square").help("achieve.manager.update") }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $makeArchFile.showIt, content: { CreateArchFile })
        .alert(vm.alertMate.msg, isPresented: $vm.alertMate.showIt, actions: {})
        .navigationTitle(Text("home.sider.achieve"))
    }
    
    private var CreateArchFile: some View {
        return NavigationStack {
            Text("achieve.no_archive.sheet.title").font(.title2).bold().padding(.bottom, 16)
            TextField("achieve.no_archive.sheet.name", text: $makeArchFile.name)
            Text("achieve.no_archive.sheet.name_p").font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("def.cancel", action: { makeArchFile.showIt = false })
            })
            ToolbarItem(placement: .confirmationAction, content: {
                Button("def.confirm", action: {
                    vm.createNewArchive(mc: mc, archName: makeArchFile.name)
                    makeArchFile.showIt = false
                })
            })
        }
    }
    
    private struct SearchBar: View {
        @State private var showSearchField: Bool = false
        @State private var typedText: String = ""
        let searchEvt: (String) -> Void
        let clearResultEvt: () -> Void
        
        var body: some View {
            HStack {
                if showSearchField {
                    TextField("achieve.search.type", text: $typedText)
                        .padding(4).frame(width: 120)
                    Button("achieve.search.do", action: { searchEvt(typedText) })
                }
                if showSearchField {
                    Button("achieve.search.clear", action: {
                        withAnimation(.smooth, { showSearchField = false })
                        typedText = ""
                        clearResultEvt()
                    })
                } else {
                    Button(
                        action: { withAnimation(.smooth, { showSearchField = true }) },
                        label: { Image(systemName: "magnifyingglass").help("achieve.search.do") }
                    )
                }
            }
        }
    }
}

#Preview {
    AchievementView()
}
