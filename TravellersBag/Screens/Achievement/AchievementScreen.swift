//
//  AchievementScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/26.
//

import SwiftUI
import Kingfisher

struct AchievementScreen: View {
    @Environment(\.managedObjectContext) private var dataManager
    @StateObject private var viewModel = AchieveModel.shared
    @State private var deleteArchive = false
    @State private var selected: AchieveList? = nil
    
    var body: some View {
        VStack {
            switch viewModel.uiPart {
            case .Loading:
                Text("app.waiting")
            case .Content:
                VStack {
                    HSplitView {
                        List(selection: $selected) {
                            ForEach(viewModel.achieveList){ single in
                                AchieveGroupEntry(entry: single).tag(single)
                            }
                        }.frame(minWidth: 130, maxWidth: 150)
                        VStack {
                            if let checked = selected {
                                List {
                                    ForEach(viewModel.achieveContent.filter({ $0.goal == checked.id }).sorted(by: { $0.id < $1.id })){ it in
                                        HStack(spacing: 8) {
                                            Toggle(isOn: .constant(it.finished), label: {}).toggleStyle(.checkbox)
                                            VStack(alignment: .leading, content: {
                                                Text(it.title!)
                                                Text(it.des!).foregroundStyle(.secondary).font(.footnote)
                                            })
                                            Spacer()
                                            if it.finished {
                                                Text(
                                                    String.localizedStringWithFormat(
                                                        NSLocalizedString("achieve.content.finished_at", comment: ""),
                                                        num2time(time: Int(it.timestamp)))
                                                ).foregroundStyle(.secondary).font(.callout)
                                            }
                                            Button(
                                                action: {
                                                    let mid = it
                                                    it.finished = !it.finished
                                                    it.timestamp = Int64(Date().timeIntervalSince1970)
                                                    viewModel.changeAchieveState(item: mid)
                                                },
                                                label: { Image(systemName: (it.finished) ? "xmark" : "checkmark") }
                                            )
                                            ZStack {
                                                Image("UI_QUALITY_ORANGE").resizable().frame(width: 36, height: 36)
                                                Image("原石").resizable().frame(width: 36, height: 36)
                                                VStack {
                                                    Spacer()
                                                    HStack {
                                                        Spacer()
                                                        Text(String(it.reward)).foregroundStyle(.white).font(.footnote)
                                                        Spacer()
                                                    }.background(.gray.opacity(0.6))
                                                }
                                            }
                                            .frame(width: 36, height: 36)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                }
                            } else {
                                Text("achieve.content.select")
                            }
                        }.frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .toolbar {
                    ToolbarItem {
                        Button(action: { deleteArchive = true }, label: { Image(systemName: "server.rack").help("achieve.manager.help") })
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
                Text("achieve.manager.help").font(.title).bold().padding(.bottom, 4)
                List {
                    ForEach(viewModel.archives, id: \.self) { single in
                        HStack(spacing: 8) {
                            Image(systemName: "archivebox").font(.title2).foregroundStyle(.tint)
                            Text(single).font(.system(size: 14))
                            Spacer()
                            Button(
                                action: {},
                                label: { Image(systemName: "square.and.arrow.down.on.square").help("achieve.manager.update") }
                            )
                            Button(action: {
                                deleteArchive = false
                                viewModel.deleteAnArchive(name: single)
                            }, label: { Image(systemName: "trash").help("achieve.manager.delete") })
                        }
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                    }
                }.frame(minHeight: 100)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button("app.cancel", action: { deleteArchive = false })
                })
                ToolbarItem(placement: .confirmationAction, content: {
                    Button("achieve.manager.export", action: {})
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
    
    func num2time(time: Int) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.string(from: Date(timeIntervalSince1970: TimeInterval(time)))
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
    
    struct AchieveGroupEntry: View {
        let entry: AchieveList
        let detail: [Substring]
        
        init(entry: AchieveList) {
            self.entry = entry
            self.detail = HoyoResKit.default.getImageWithNameAndType(type: "AchievementIcon", name: entry.icon).split(separator: "@")
        }
        var body: some View {
            HStack(spacing: 8) {
                if String(detail[0]) == "L" {
                    Image(nsImage: NSImage(contentsOfFile: String(detail[1])) ?? NSImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                } else {
                    KFImage(URL(string: String(detail[1])))
                        .loadDiskFileSynchronously(true)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                }
                Text(entry.name).font(.headline)
            }.padding(2)
        }
    }
}
