//
//  AnnoViewModel.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/23.
//

import Foundation

class AnnoViewModel: ObservableObject, @unchecked Sendable {
    let annoRepo = AnnounceRepo()
    let annoGachaRepo = AnnoGachaPoolRepo()
    let annoDetailRepo = AnnoDetailRepo()
    @Published var uiState: AnnoUiState = .init()
    
    func loadFeed() async {
        do {
            let result = try await annoRepo.readAsync()
            await MainActor.run {
                uiState.annoFeed = result
                uiState.isLoading = false
            }
        } catch {
            await MainActor.run {
                uiState.alert.showAlert(msg: "Failed to fetch anno: \(error.localizedDescription)", type: .Error)
            }
        }
    }
    
    func loadGachaFeed() async {
        let result = try? await annoGachaRepo.readAsync()
        await MainActor.run {
            uiState.gachaFeed = result
        }
    }
    
    func loadAnnoDetail() async {
        let result = try? await annoDetailRepo.readAsync()
        await MainActor.run {
            uiState.annoDetail = result
        }
    }
    
    func getRequiredAnnoDetail(annId: Int) -> AnnoDetailStruct.DetailList.AnnoUnit? {
        let datalist = uiState.annoDetail?.data
        let result = datalist?.list.filter({ $0.annId == annId }).first
        return result
    }
}

extension AnnoViewModel {
    struct AnnoUiState {
        var isLoading: Bool = true
        var annoFeed: AnnounceRepo.AnnoStruct? = nil
        var gachaFeed: AnnoGachaPoolRepo.GachaPools? = nil
        var alert: AlertMate = .init()
        var annoDetail: AnnoDetailStruct? = nil
    }
}
