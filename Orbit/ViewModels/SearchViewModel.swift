//
//  SearchViewModel.swift
//  Orbit
//
//  Created by NoriDev on 7/7/25.
//

import Foundation
import VRCKit
import SwiftUI

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var users: [LimitedUser] = []
    @Published var isSearching: Bool = false
    @Published var didSearch: Bool = false
    @Published var canLoadMore = true
    private var offset = 0
    private let fetchCount = 50
    
    var appVM: AppViewModel
    
    init(appVM: AppViewModel) {
        self.appVM = appVM
    }
    
    func searchUsers() async {
        didSearch = true
        offset = 0
        canLoadMore = true
        
        guard !searchText.isEmpty else {
            users = []
            return
        }
        
        users = []
        isSearching = true
        await fetchUsers()
        isSearching = false
    }
    
    func loadMoreUsers() async {
        guard canLoadMore, !isSearching else { return }
        
        isSearching = true
        await fetchUsers()
        isSearching = false
    }
    
    func clearAndReset() {
        searchText = ""
        users = []
        offset = 0
        canLoadMore = true
        didSearch = false
    }
    
    private func fetchUsers() async {
        do {
            let service = appVM.services.userService
            let newUsers = try await service.searchUser(displayName: searchText, n: fetchCount, offset: offset)
            
            users.append(contentsOf: newUsers)
            offset += newUsers.count
            canLoadMore = newUsers.count == fetchCount
        } catch {
            appVM.handleError(error)
            canLoadMore = false
        }
    }
}
