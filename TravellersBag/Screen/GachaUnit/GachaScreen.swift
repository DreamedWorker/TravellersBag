//
//  GachaScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/12/6.
//

import SwiftUI
import AlertToast

struct GachaScreen: View {
    @StateObject private var vm = GachaScreenViewModel()
    
    var body: some View {
        VStack {
            if vm.showContent {
                let character = vm.currentAccountGachaRecords
                    .filter { $0.gachaType == vm.characterGacha || $0.gachaType == "400" }
                    .sorted(by: { Int($0.id)! < Int($1.id)! }) // 按照时间先后顺序原地排序（才发现这个id才是真正排序时的依据 用time代表的时间戳一定出事）
                let weapon = vm.currentAccountGachaRecords
                    .filter({ $0.gachaType == vm.weaponGacha }).sorted(by: { Int($0.id)! < Int($1.id)! })
                let resident = vm.currentAccountGachaRecords
                    .filter({ $0.gachaType == vm.residentGacha }).sorted(by: { Int($0.id)! < Int($1.id)! })
                let collection = vm.currentAccountGachaRecords
                    .filter({ $0.gachaType == vm.collectionGacha }).sorted(by: { Int($0.id)! < Int($1.id)! })
                ScrollView(.horizontal, content: {
                    LazyHStack(alignment: .top) {
                        GachaBulletin(specificData: character, gachaTitle: "gacha.home.avatar")
                        GachaBulletin(specificData: weapon, gachaTitle: "gacha.home.weapon")
                        GachaBulletin(specificData: resident, gachaTitle: "gacha.home.resident")
                        GachaBulletin(specificData: collection, gachaTitle: "gacha.home.collection")
                    }
                })
            } else {
                DefaultPane(fetchEvt: {
                    vm.showWaitingDialog = true
                    Task { await vm.updateDataFromCloud() }
                })
            }
        }
        .alert(vm.alertMate.msg, isPresented: $vm.alertMate.showIt, actions: {})
        .toast(isPresenting: $vm.showWaitingDialog, alert: { AlertToast(displayMode: .alert, type: .loading) })
    }
}

private struct DefaultPane: View {
    var fetchEvt: () -> Void
    
    var body: some View {
        VStack {
            if TBDao.getDefaultAccount() != nil {
                Image("dailynote_empty").resizable().frame(width: 72, height: 72)
                Text("gacha.empty.title").font(.title2).bold().padding(.bottom, 16)
                Button(action: fetchEvt, label: { Text("gacha.empty.fetch") }).buttonStyle(BorderedProminentButtonStyle())
            } else {
                Image("dailynote_empty").resizable().frame(width: 72, height: 72)
                Text("gacha.empty.login").font(.title2).bold()
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
    }
}
