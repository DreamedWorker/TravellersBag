//
//  GachaActivities.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/25.
//

import SwiftUI
import SwiftyJSON
import Kingfisher

struct GachaActivities: View {
    @StateObject private var viewModel = ActivityModel()
    @State private var selectedActivity: ActivityModel.ActivityEntry? = nil
    
    var gachaRecord: [GachaItem]
    init(gachaRecord: [GachaItem]) {
        self.gachaRecord = gachaRecord.sorted(by: { Int($0.id!)! < Int($1.id!)! })
    }
    
    var body: some View {
        if viewModel.showUI {
            HSplitView {
                List(selection: $selectedActivity, content: {
                    ForEach(viewModel.processedList){ single in
                        VStack(alignment: .leading, content: {
                            Text(single.name).font(.headline)
                            HStack {
                                Text("gacha.history.version")
                                Spacer()
                                Text(single.version).foregroundStyle(.secondary)
                            }.font(.footnote)
                        }).tag(single)
                    }
                }).frame(minWidth: 130, maxWidth: 150)
                VStack {
                    if let selected = selectedActivity {
                        //DetailView(entry: selected, allList: gachaRecord)
                    } else {
                        Text("app.cancel")
                    }
                }
                .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            Text("app.cancel").onAppear { viewModel.initSomething(rootList: gachaRecord) }
        }
    }
    
    private struct DetailView: View {
        let entry: GachaActivities.ActivityModel.ActivityEntry
        var orange: [String]
        var purple: [String]
        var all: [GachaItem]
        var otherItems: [GachaItem]
        
        init(entry: GachaActivities.ActivityModel.ActivityEntry, allList: [GachaItem]) {
            self.entry = entry
            orange = []
            for i in entry.oragon {
                orange.append(HoyoResKit.default.getGachaItemIcon(key: String(i)))
            }
            purple = []
            for i in entry.purple {
                purple.append(HoyoResKit.default.getGachaItemIcon(key: String(i)))
            }
            self.all = allList
            
            var temp: [Int] = []
            temp.append(contentsOf: entry.oragon); temp.append(contentsOf: entry.purple)
            let mid = all.filter({ it in temp.contains(Int(HoyoResKit.default.getIdByName(name: it.name!))!) })
            otherItems = mid
        }
        
        var body: some View {
            ScrollView {
                KFImage(URL(string: entry.banner))
                    .loadDiskFileSynchronously(true)
                    .resizable()
                    .frame(height: 150)
                VStack(alignment: .leading) {
                    Text("gacha.history.five").font(.title3).bold()
                    HStack {
                        ForEach(orange, id: \.self) { single in
                            DisplayCell(single: single, rankType: "5", all: all, entry: entry)
                            .padding(4)
                            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                        }
                        Spacer()
                    }
                    Text("gacha.history.four").font(.title3).bold().padding(.top, 8)
                    HStack {
                        ForEach(purple, id: \.self) { single in
                            DisplayCell(single: single, rankType: "4", all: all, entry: entry)
                            .padding(4)
                            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                        }
                        Spacer()
                    }.padding(.bottom, 16)
                    Grid {
                        ForEach(otherItems){ single in
                            Text(single.name!)
                        }
                    }
                }.padding(.top, 8)
            }
        }
        
        struct DisplayCell: View {
            let single: String
            let rankType: String
            var all: [GachaItem]
            let entry: GachaActivities.ActivityModel.ActivityEntry
            
            var body: some View {
                VStack {
                    ZStack {
                        switch rankType {
                        case "5":
                            Image("UI_QUALITY_ORANGE")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                        case "4":
                            Image("UI_QUALITY_PURPLE")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                        default:
                            Image("UI_QUALITY_NONE")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                        }
                        if single.split(separator: "@")[0] == "C" {
                            KFImage(URL(string: String(single.split(separator: "@")[1])))
                                .loadDiskFileSynchronously(true)
                                .resizable()
                                .frame(width: 48, height: 48)
                        } else {
                            Image(nsImage: NSImage(contentsOfFile: String(single.split(separator: "@")[1])) ?? NSImage())
                                .resizable()
                                .frame(width: 48, height: 48)
                        }
                    }
                    Text(
                        String(
                            getCount(
                                allList: all,
                                id: Int(
                                    HoyoResKit.default.getIdByName(
                                        name: String(single.split(separator: "@")[2])
                                    )
                                )!
                            )
                        )
                    )
                }
            }
            
            func getCount(allList: [GachaItem], id: Int) -> Int {
                let name = HoyoResKit.default.getNameById(id: String(id))
                if name != "?" {
                    let tempList = allList.filter({ isDateInRange(o: $0.time!, a: entry.from, b: entry.to) })
                        .filter({ $0.name! == name })
                    return tempList.count
                } else {
                    return 0
                }
            }
            
            private func isDateInRange(o: Date, a: Date, b: Date) -> Bool {
                let isInRange = o.compare(a) != .orderedAscending && o.compare(b) != .orderedDescending
                return isInRange
            }
        }
    }
    
    class ActivityModel: ObservableObject {
        @Published var processedList: [ActivityEntry] = []
        @Published var showUI = false
        let fs = FileManager.default
        var activities: JSON? = nil
        
        func initSomething(rootList: [GachaItem]) {
            let localFile = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appending(component: "globalStatic").appending(component: "cloud").appending(component: "GachaEvent.json")
            if fs.fileExists(atPath: localFile.toStringPath()) && !rootList.isEmpty {
                activities = try? JSON(data: FileHandler.shared.readUtf8String(path: localFile.toStringPath()).data(using: .utf8)!)
                for i in activities!.arrayValue {
                    processedList.append(
                        ActivityEntry(
                            id: UUID().uuidString, name: i["Name"].stringValue, version: i["Version"].stringValue,
                            banner: i["Banner"].stringValue, from: dateTransfer(str: i["From"].stringValue),
                            to: dateTransfer(str: i["To"].stringValue), type: i["Type"].intValue,
                            oragon: i["UpOrangeList"].arrayObject as! [Int], purple: i["UpPurpleList"].arrayObject as! [Int])
                    )
                }
                processedList = processedList
                    .sorted(by: { $0.from < $1.from })
                    .filter({ isDateInRange(o: $0.from, a: rootList.first!.time!, b: rootList.last!.time!) })
            }
            if activities != nil {
                showUI = true
            }
        }
        
        private func dateTransfer(str: String) -> Date {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            return df.date(from: str)!
        }
        
        private func isDateInRange(o: Date, a: Date, b: Date) -> Bool {
            let isInRange = o.compare(a) != .orderedAscending && o.compare(b) != .orderedDescending
            return isInRange
        }
        
        struct ActivityEntry: Identifiable, Hashable {
            var id: String
            var name: String
            var version: String
            var banner: String
            var from: Date
            var to: Date
            var type: Int
            var oragon: [Int]
            var purple: [Int]
        }
    }
}
