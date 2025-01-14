//
//  GachaHistoryActivity.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/14.
//

import SwiftUI
import Kingfisher
import SwiftyJSON

struct GachaHistoryActivity: View {
    @StateObject private var vm = GachaHistoryActivityViewModel()
    @State private var selectedActivity: ActivityEntry? = nil
    @State private var showUpdate: Bool = false
    
    let thisAccountRecord: [GachaItem]
    let dismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            if vm.showUI {
                HSplitView {
                    List(selection: $selectedActivity) {
                        Button("gacha.history.refresh", action: { showUpdate = true })
                        ForEach(vm.processedList){ single in
                            VStack(alignment: .leading, content: {
                                Text(single.name).font(.headline)
                                HStack {
                                    Text("gacha.history.version")
                                    Spacer()
                                    Text(single.version).foregroundStyle(.secondary)
                                }.font(.footnote)
                            }).tag(single)
                        }
                    }.frame(minWidth: 130, maxWidth: 150)
                    LazyVStack {
                        if let selected = selectedActivity {
                            GachaHistoryDetail(
                                entry: selected,
                                getCount: { it in vm.getItemTimes(id: it, entry: selected) },
                                processed: vm.countOccurrences(entry: selected)
                            )
                        } else {
                            Text("gacha.history.select").padding(32)
                        }
                    }.frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                Text("def.holding")
                    .padding()
                    .onAppear {
                        vm.initSomething(rootList: thisAccountRecord)
                    }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("def.cancel", action: dismiss)
            })
        }
        .alert("gacha.history.uniqueUpdate", isPresented: $showUpdate, actions: {})
    }
    
    private struct ItemCell: View {
        let msg: String
        let count: Int
        
        var body: some View {
            VStack {
                ZStack {
                    switch String(msg.split(separator: "@")[3]) {
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
                    if msg.split(separator: "@")[0] == "C" {
                        KFImage(URL(string: String(msg.split(separator: "@")[1])))
                            .loadDiskFileSynchronously(true)
                            .resizable()
                            .frame(width: 48, height: 48)
                    } else {
                        Image(nsImage: NSImage(contentsOfFile: String(msg.split(separator: "@")[1])) ?? NSImage())
                            .resizable()
                            .frame(width: 48, height: 48)
                    }
                }
                Text(String(count))
            }
            .help(msg.split(separator: "@")[2])
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
        }
    }
}

extension GachaHistoryActivity {
    class GachaHistoryActivityViewModel: ObservableObject {
        @Published var processedList: [ActivityEntry] = []
        @Published var showUI = false
        
        var rootList: [GachaItem] = []
        
        func initSomething(rootList: [GachaItem]) {
            self.rootList.removeAll()
            self.rootList = rootList
            self.rootList = rootList.sorted(by: { string2date(str: $0.time) < string2date(str: $1.time) })
            for i in ResHandler.default.gachaEvent {
                processedList.append(
                    ActivityEntry(
                        id: UUID().uuidString, name: i["Name"].stringValue, version: i["Version"].stringValue,
                        banner: i["Banner"].stringValue, from: dateTransfer(str: i["From"].stringValue),
                        to: dateTransfer(str: i["To"].stringValue), type: i["Type"].intValue,
                        oragon: i["UpOrangeList"].arrayObject as! [Int], purple: i["UpPurpleList"].arrayObject as! [Int])
                )
            }
            processedList = processedList
                .sorted(by: { $0.from > $1.from })
                .filter({ isDateInRange(
                    o: $0.from,
                    a: string2date(str: self.rootList.first!.time),
                    b: string2date(str: self.rootList.last!.time)) }
                )
            showUI = true
        }
        
        func countOccurrences(entry: ActivityEntry) -> [String: Int] {
            var array: [String] = []
            for i in requiredProcessedList(entry: entry) {
                array.append(i.name)
            }
            var countDict: [String: Int] = [:]
            for item in array {
                // 如果字典中已存在该键，则增加其值；否则，初始化其值为1
                countDict[item] = (countDict[item] ?? 0) + 1
            }
            return countDict
        }
        
        func requiredProcessedList(entry: ActivityEntry) -> [GachaItem] {
            var temp: [Int] = []
            temp.append(contentsOf: entry.oragon); temp.append(contentsOf: entry.purple)
            func notExists(some: GachaItem) -> Bool {
                if temp.contains(Int(ResHandler.default.getIdByName(name: some.name))!) {
                    return false
                } else {
                    return true
                }
            }
            let mid = rootList
                .filter({ isDateInRange(o: string2date(str: $0.time), a: entry.from, b: entry.to) })
                .filter({ $0.gachaType == String(entry.type) })
                .filter({ it in notExists(some: it) })
            return mid
        }
        
        func getItemTimes(id: Int, entry: ActivityEntry) -> Int {
            let name = ResHandler.default.getGachaItemName(key: String(id))
            if name == "?" { return 0 }
            let mid = rootList.filter({ isDateInRange(o: string2date(str: $0.time), a: entry.from, b: entry.to) })
                .filter({ $0.name == name })
            return mid.count
        }
        
        private func dateTransfer(str: String) -> Date {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            return df.date(from: str)!
        }
        
        /// 字符串转时间对象
        private func string2date(str: String) -> Date {
            let format = DateFormatter()
            format.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return format.date(from: str)!
        }
        
        private func isDateInRange(o: Date, a: Date, b: Date) -> Bool {
            let isInRange = o.compare(a) != .orderedAscending && o.compare(b) != .orderedDescending
            return isInRange
        }
    }
}
