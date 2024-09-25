//
//  GachaActivities.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/25.
//

import SwiftUI
import SwiftyJSON
import Kingfisher
import WaterfallGrid

struct GachaActivities: View {
    @StateObject private var viewModel = ActivityModel.shared
    @State private var selectedActivity: ActivityModel.ActivityEntry? = nil
    @State private var updateAlert = false
    
    var gachaRecord: [GachaItem]
    init(gachaRecord: [GachaItem]) {
        self.gachaRecord = gachaRecord.sorted(by: { Int($0.id!)! < Int($1.id!)! })
    }
    
    var body: some View {
        VStack {
            if viewModel.showUI {
                HSplitView {
                    List(selection: $selectedActivity, content: {
                        Button("gacha.history.refresh", action: { updateAlert = true })
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
                            DetailView(
                                entry: selected,
                                getCount: { it in viewModel.getItemTimes(id: it, entry: selected) },
                                processed: viewModel.countOccurrences(entry: selected)
                            )
                        } else {
                            Text("gacha.history.select")
                        }
                    }
                    .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                }
                .alert(
                    "app.notice", isPresented: $updateAlert,
                    actions: {
                        Button("app.confirm", action: {
                            viewModel.showUI = false
                            Task { await viewModel.updateGachaHistory() }
                        })
                        Button(role: .cancel, action: { updateAlert = false }, label: { Text("app.cancel") })
                    },
                    message: { Text("gacha.history.refresh_p")}
                )
            } else {
                Text("app.waiting")
            }
            ZStack {}.frame(width: 0, height: 0).onAppear { viewModel.initSomething(rootList: gachaRecord) }
        }
    }
    
    private struct DetailView: View {
        let entry: ActivityModel.ActivityEntry
        let getCount: (Int) -> Int
        let processed: [String: Int]
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading) {
                    KFImage(URL(string: entry.banner))
                        .loadDiskFileSynchronously(true)
                        .resizable()
                        .frame(height: 150)
                        .padding(.bottom, 16)
                    Text("gacha.history.five").bold()
                    HStack {
                        ForEach(entry.oragon, id: \.self){ it in
                            ItemCell(msg: HoyoResKit.default.getGachaItemIcon(key: String(it)), count: getCount(it))
                        }
                        Spacer()
                    }
                    Text("gacha.history.four").bold()
                    HStack {
                        ForEach(entry.purple, id: \.self){ it in
                            ItemCell(msg: HoyoResKit.default.getGachaItemIcon(key: String(it)), count: getCount(it))
                        }
                        Spacer()
                    }
                    Text("gacha.history.other").bold()
                    WaterfallGrid(processed.keys.sorted(), id: \.self){ single in
                        ItemCell(msg: HoyoResKit.default.getGachaItemIcon(key: HoyoResKit.default.getIdByName(name: single)), count: processed[single] ?? 0)
                    }.gridStyle(columns: 7)
                }
            }
            .padding(4)
        }
        
        func addThisOne(name: String) -> Bool {
            let itemId = Int(HoyoResKit.default.getIdByName(name: name))!
            if itemId == 0 { return false }
            if entry.oragon.contains(itemId) || entry.purple.contains(itemId) {
                return false
            } else {
                return true
            }
        }
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
    
    class ActivityModel: ObservableObject {
        static let shared = ActivityModel()
        private init() {}
        
        @Published var processedList: [ActivityEntry] = []
        @Published var showUI = false
        let fs = FileManager.default
        var activities: JSON? = nil
        var rootList: [GachaItem] = []
        
        func initSomething(rootList: [GachaItem]) {
            self.rootList.removeAll()
            self.rootList = rootList
            let localFile = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appending(component: "globalStatic").appending(component: "cloud").appending(component: "GachaEvent.json")
            if fs.fileExists(atPath: localFile.toStringPath()) && !rootList.isEmpty {
                activities = try? JSON(data: FileHandler.shared.readUtf8String(path: localFile.toStringPath()).data(using: .utf8)!)
                processedList.removeAll()
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
                    .sorted(by: { $0.from > $1.from })
                    .filter({ isDateInRange(o: $0.from, a: rootList.first!.time!, b: rootList.last!.time!) })
            }
            if activities != nil {
                showUI = true
            }
        }
        
        func updateGachaHistory() async {
            func getPath() throws -> URL {
                let localRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    .appending(component: "globalStatic")
                if fs.fileExists(atPath: localRoot.toStringPath()) {
                    let sunDir = localRoot.appending(component: "cloud")
                    if fs.fileExists(atPath: sunDir.toStringPath()) {
                        let localFile = sunDir.appending(component: "GachaEvent.json")
                        if fs.fileExists(atPath: localFile.toStringPath()) {
                            return localFile
                        } else { throw NSError(domain: "icu.bluedream.travellersbag.gacha_history", code: 2) }
                    } else { throw NSError(domain: "icu.bluedream.travellersbag.gacha_history", code: 2) }
                } else { throw NSError(domain: "icu.bluedream.travellersbag.gacha_history", code: 2) }
            }
            do {
                let filePath = try getPath()
                let request = URLRequest(url: URL(string: "https://static-next.snapgenshin.com/d/meta/metadata/Genshin/CHS/GachaEvent.json")!)
                try await httpSession().download2File(url: filePath, req: request)
                DispatchQueue.main.async { [self] in
                    GlobalUIModel.exported.makeAnAlert(type: 1, msg: "更新成功")
                    initSomething(rootList: rootList)
                }
            } catch {
                DispatchQueue.main.async { [self] in
                    GlobalUIModel.exported.makeAnAlert(type: 3, msg: "更新失败，\(error.localizedDescription)")
                    initSomething(rootList: rootList)
                }
            }
        }
        
        func countOccurrences(entry: ActivityEntry) -> [String: Int] {
            var array: [String] = []
            for i in requiredProcessedList(entry: entry) {
                array.append(i.name!)
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
                if temp.contains(Int(HoyoResKit.default.getIdByName(name: some.name!))!) {
                    return false
                } else {
                    return true
                }
            }
            let mid = rootList
                .filter({ isDateInRange(o: $0.time!, a: entry.from, b: entry.to) })
                .filter({ $0.gachaType! == String(entry.type) })
                .filter({ it in notExists(some: it) })
            return mid
        }
        
        func getItemTimes(id: Int, entry: ActivityEntry) -> Int {
            let name = HoyoResKit.default.getNameById(id: String(id))
            if name == "?" { return 0 }
            let mid = rootList.filter({ isDateInRange(o: $0.time!, a: entry.from, b: entry.to) })
                .filter({ $0.name! == name })
            return mid.count
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
