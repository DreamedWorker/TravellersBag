//
//  AnnoHotActivity.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/27.
//

import SwiftUI
import Kingfisher

struct AnnoHotActivity: View {
    @StateObject private var vm = HotActivityHelper()
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            if !vm.activities.isEmpty {
                LazyHStack(spacing: 8) {
                    let start = Date.now
                    ForEach(vm.activities) { activity in
                        HotItem(activity: activity, start: start)
                    }
                }
            }
        }
        .onAppear {
            Task.detached {
                await vm.loadFileAndParse()
            }
        }
    }
}

fileprivate struct HotItem: View {
    let activity: AnnoHotActStruct.ActivityList.ChildElement.PurpleList
    let start: Date
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(activity.abstract).font(.footnote.bold()).foregroundStyle(.secondary)
                    Text(activity.title).font(.title3.bold()).padding(.bottom)
                    Label(
                        String.localizedStringWithFormat(
                            NSLocalizedString("anno.label.date", comment: ""),
                            activity.createTime,
                            HotActivityHelper.timestamp2string(time: Int(activity.endTime)!)
                        ),
                        systemImage: "calendar"
                    )
                    .font(.callout).foregroundStyle(.secondary)
                    if activity.endTime != "0" {
                        let end = HotActivityHelper.timestamp2string(time: Int(activity.endTime)!).dateFromFormattedString()
                        let gap = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: start, to: end)
                        if (gap.minute ?? 0) >= 0 {
                            Label(
                                String.localizedStringWithFormat(
                                    NSLocalizedString("anno.label.timer", comment: ""),
                                    String(gap.hour ?? 0), String(gap.minute ?? 0)
                                ),
                                systemImage: "timer"
                            ).font(.callout).foregroundStyle(.secondary)
                        } else {
                            Label("anno.label.ended", systemImage: "timer").font(.callout).foregroundStyle(.secondary)
                        }
                    } else {
                        Label("anno.label.unknown", systemImage: "timer").font(.callout).foregroundStyle(.secondary)
                    }
                }
                KFImage.url(URL(string: activity.icon))
                    .loadDiskFileSynchronously(true)
                    .resizable()
                    .clipShape(Circle())
                    .frame(width: 64, height: 64)
            }
            Spacer()
        }
        .onTapGesture {
            NSWorkspace.shared.open(URL(string: activity.url) ?? URL(string: "https://miyoushe.com")!)
        }
        .frame(minHeight: 100)
        .padding(8)
        .background(.secondary.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

fileprivate class HotActivityHelper: AutocheckedKey, ObservableObject, @unchecked Sendable {
    private let hotDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(path: "Anno")
    private let hotFile: URL
    @Published var activities: [AnnoHotActStruct.ActivityList.ChildElement.PurpleList] = []
    
    init() {
        self.hotFile = hotDir.appending(components: "HotActivity.json")
        super.init(configKey: "hotActivityLastCheck")
        if !FileManager.default.fileExists(atPath: hotDir.path(percentEncoded: false)) {
            try! FileManager.default.createDirectory(at: hotDir, withIntermediateDirectories: true)
        }
        if !FileManager.default.fileExists(atPath: self.hotFile.path(percentEncoded: false)) {
            FileManager.default.createFile(atPath: self.hotFile.path(percentEncoded: false), contents: nil)
        }
    }
    
    func loadFileAndParse() async {
        func loadFromNetwork() async throws {
            let fileRequest = RequestBuilder.buildRequest(
                method: .GET, host: Endpoints.ActApiTakumi, path: "/common/blackboard/ys_obc/v1/home/position",
                queryItems: [.init(name: "app_sn", value: "ys_obc")]
            )
            let result = try await NetworkClient.simpleDataClient(request: fileRequest, type: AnnoHotActStruct.self)
            try JSONEncoder().encode(result).write(to: hotFile)
            await parseValue(localData: result)
            storeFetch(date: Date.now)
        }
        
        func parseValue(localData: AnnoHotActStruct) async {
            if let hotspot = localData.data.list.filter({ $0.name == "热点追踪" }).first {
                if let requiredList = hotspot.children.first {
                    if let innerList = requiredList.children.filter({ $0.name == "近期活动" }).first {
                        for single in innerList.list {
                            await MainActor.run {
                                activities.append(single)
                            }
                        }
                    }
                }
            }
        }
        
        do {
            if let localData = try? JSONDecoder().decode(AnnoHotActStruct.self, from: Data(contentsOf: hotFile)) {
                await parseValue(localData: localData)
            } else {
                try await loadFromNetwork()
            }
        } catch {
            print("Failed to fetch hot activity, because: \(error)")
        }
    }
    
    static func timestamp2string(time: Int) -> String {
        if time == 0 {
            return NSLocalizedString("anno.label.unknown", comment: "")
        }
        let confirmedTime = convert13DigitsTo10(String(time))
        return confirmedTime.formatTimestamp()
    }
    
    static private func convert13DigitsTo10(_ input: String) -> Int {
        if input.count > 10 {
            let startIndex = input.startIndex
            let endIndex = input.index(startIndex, offsetBy: 10)
            let tenDigitString = String(input[startIndex..<endIndex])
            return Int(tenDigitString)!
        } else if input.count == 10 {
            return Int(input)!
        } else {
            return 0
        }
    }
}
