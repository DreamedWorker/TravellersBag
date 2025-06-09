//
//  AchievementView.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/6/9.
//

import SwiftUI
import SwiftData

struct AchievementView: View {
    @Environment(\.modelContext) private var operation
    @StateObject private var viewModel = AchieveViewModel()
    @State private var showAddSheet: Bool = false
    @State private var archNameInput: String = ""
    @State private var selectedGroup: AchievementGroupElement? = nil
    @State private var showSearch: Bool = false
    
    var body: some View {
        NavigationStack {
            switch viewModel.uiState.showLogic {
            case .waiting:
                VStack{}
                    .onAppear {
                        viewModel.initView(operation: operation)
                    }
            case .lackFiles:
                ContentUnavailableView("achieve.lackFiles", systemImage: "externaldrive.badge.exclamationmark")
            case .lackArchs:
                ContentUnavailableView("achieve.lackArchs", systemImage: "externaldrive.badge.plus", description: Text("achieve.lackArchs.exp"))
            case .fine:
                HSplitView {
                    List(selection: $selectedGroup) {
                        ForEach(viewModel.uiState.achievementGroup, id: \.order) { sing in
                            AchieveGroupEntry(entry: sing, summary: viewModel.countItems(for: sing.id)).tag(sing)
                        }
                    }
                    .background(.regularMaterial)
                    .frame(minWidth: 150, maxWidth: 170)
                    ScrollView(showsIndicators: false) {
                        LazyVStack {
                            if let selected = selectedGroup {
                                let items = viewModel.uiState.records.filter({ $0.goal == selected.id })
                                ForEach(items) { item in
                                    HStack {
                                        Toggle(isOn: .constant(item.finished), label: {})
                                            .toggleStyle(.checkbox)
                                            .controlSize(.large)
                                        VStack(alignment: .leading) {
                                            Text(item.title)
                                            Text(item.des).foregroundStyle(.secondary).font(.footnote)
                                        }
                                        Spacer()
                                        if item.finished {
                                            Text(item.timestamp.formatTimestamp()).font(.callout)
                                        }
                                        ZStack {
                                            Image("UI_QUALITY_ORANGE").resizable().frame(width: 36, height: 36)
                                            Image("原石").resizable().frame(width: 36, height: 36)
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Spacer()
                                                    Text(String(item.reward)).foregroundStyle(.white).font(.footnote)
                                                    Spacer()
                                                }.background(.gray.opacity(0.6))
                                            }
                                        }
                                        .frame(width: 36, height: 36)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        Button(
                                            action: {
                                                item.finished = !item.finished
                                                item.timestamp = Int(Date().timeIntervalSince1970)
                                                try! operation.save()
                                            },
                                            label: { Image(systemName: (item.finished) ? "xmark" : "checkmark") }
                                        )
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.background))
                                }
                            }
                        }
                        .padding(8)
                    }.frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .sheet(isPresented: $showAddSheet, content: {
            NavigationStack {
                Text("achieve.add.title").font(.title.bold()).padding(.bottom)
                TextField("achieve.add.name", text: $archNameInput).padding(.bottom)
                Image(systemName: "info.circle").foregroundStyle(.accent)
                Text("achieve.add.tip").foregroundStyle(.secondary).font(.footnote)
            }
            .padding()
            .interactiveDismissDisabled(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button("app.cancel", action: {
                        showAddSheet = false
                        archNameInput = ""
                    })
                })
                ToolbarItem(placement: .confirmationAction, content: {
                    Button("app.confirm", action: {
                        showAddSheet = false
                        do {
                            let name = archNameInput
                            archNameInput = ""
                            try viewModel.createArch(name: name, operation: operation)
                        } catch {
                            viewModel.uiState.mate.showAlert(msg: error.localizedDescription, type: .Error)
                        }
                    })
                })
            }
        })
        .toolbar {
            ToolbarItem {
                Button(action: { showAddSheet = true }, label: { Image(systemName: "plus") })
            }
            ToolbarItem {
                HStack {
                    if showSearch {
                        SearchBar(searchEvt: { it in}, clearResultEvt: {})
                    } else {
                        Button(action: { showSearch = true }, label: { Image(systemName: "magnifyingglass") })
                    }
                }
            }
        }
    }
    
    private struct SearchBar: View {
        @State private var typedText: String = ""
        let searchEvt: (String) -> Void
        let clearResultEvt: () -> Void
        
        var body: some View {
            HStack {
                TextField("achieve.search.type", text: $typedText)
                    .padding(4).frame(width: 120)
                Button("achieve.search.do", action: { searchEvt(typedText) })
                Button("achieve.search.clear", action: {
                    typedText = ""
                    clearResultEvt()
                })
            }
        }
    }
}

#Preview {
    AchievementView()
}
