//
//  AchievementScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/26.
//

import SwiftUI

struct AchievementScreen: View {
    @Environment(\.managedObjectContext) private var dataManager
    @StateObject private var viewModel = AchieveModel.shared
    @State private var deleteArchive = false
    
    var body: some View {
        VStack {
            switch viewModel.uiPart {
            case .Loading:
                Text("app.waiting")
            case .Content:
                VStack {
                    Text("app.name")
                    Text(viewModel.achieveContent.count.description)
                }
                .toolbar {
                    ToolbarItem {
                        Button(action: { deleteArchive = true }, label: { Image(systemName: "trash") })
                    }
                }
            case .NoAccount:
                NoArchive
            case .NoResource:
                NoResource
            }
        }
        .onAppear { viewModel.initSomething(dm: dataManager) }
        .sheet(isPresented: $deleteArchive, content: {
            NavigationStack {
                List {
                    ForEach(viewModel.archives, id: \.self) { single in
                        HStack(spacing: 8) {
                            Image(systemName: "archivebox")
                            Text(single)
                            Spacer()
                            Button(action: {
                                deleteArchive = false
                                viewModel.deleteAnArchive(name: single)
                            }, label: { Image(systemName: "trash") })
                        }.padding(4)
                    }
                }.frame(minHeight: 100)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button("app.cancel", action: { deleteArchive = false })
                })
            }
        })
        .sheet(isPresented: $viewModel.makeArchFile.showIt, content: {
            NavigationStack {
                Text("achieve.no_archive.sheet.title").font(.title2).bold().padding(.bottom, 16)
                TextField("achieve.no_archive.sheet.name", text: $viewModel.makeArchFile.name)
                Text("achieve.no_archive.sheet.name_p").font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button("app.cancel", action: { viewModel.makeArchFile.showIt = false })
                })
                ToolbarItem(placement: .confirmationAction, content: {
                    Button("app.confirm", action: { viewModel.createNewArchive() })
                })
            }
        })
    }
    
    var NoArchive: some View {
        return VStack {
            Image("expecting_but_nothing").resizable().scaledToFit().frame(width: 72, height: 72)
            Text("achieve.no_archive.title").font(.title2).bold().padding(.vertical, 4)
            Button("achieve.no_archive.make", action: { viewModel.makeArchFile.showIt = true }).buttonStyle(BorderedProminentButtonStyle())
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
    }
    
    var NoResource: some View {
        return VStack {
            Image("expecting_but_nothing").resizable().scaledToFit().frame(width: 72, height: 72)
            Text("achieve.no_resource.title").font(.title2).bold().padding(.vertical, 4)
            Button("achieve.no_resource.download", action: {
                Task { await viewModel.downloadResource() }
            }).buttonStyle(BorderedProminentButtonStyle())
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
    }
}
