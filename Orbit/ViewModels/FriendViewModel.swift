//
//  FriendViewModel.swift
//  Orbit
//
//  Created by makinosp on 2024/06/09.
//

import Foundation
import Observation
import VRCKit

@Observable @MainActor
final class FriendViewModel {
    @ObservationIgnored var appVM: AppViewModel?
    @ObservationIgnored var favoriteFriends: [FavoriteFriend] = []
    @ObservationIgnored private let historyVM = FriendHistoryViewModel.shared
    var onlineFriends: [Friend] = []
    var offlineFriends: [Friend] = []
    var filterResultFriends: [Friend] = []
    var friendsLocations: [FriendsLocation] = []
    var filterUserStatus: Set<UserStatus> = []
    var filterFavoriteGroups: Set<FavoriteGroup.ID> = []
    var filterText: String = ""
    var sortType: SortType = .loginLatest
    var isFetchingAllFriends = true
    var isProcessingFilter = false
    var isCacheCorrupted = false
    private let localFriendsKey = "localFriendsList"

    init() {
        restoreFilter()
    }

    func restoreFilter() {
        if let filterUserStatus = UserDefaults.standard.array(
            forKey: Constants.Keys.filterUserStatus.rawValue
        ) as? [String] {
            let statuses = filterUserStatus.map({ UserStatus(rawValue: $0)}).compactMap(\.self)
            self.filterUserStatus = Set(statuses)
        }
        if let filterFavoriteGroups = UserDefaults.standard.array(
            forKey: Constants.Keys.filterFavoriteGroups.rawValue
        ) as? [FavoriteGroup.ID] {
            self.filterFavoriteGroups = Set(filterFavoriteGroups)
        }
        if let sortType = UserDefaults.standard.string(forKey: Constants.Keys.sortType.rawValue),
           let unwrapped = SortType(rawValue: sortType) {
            self.sortType = unwrapped
        }
    }

    func setAppVM(_ appVM: AppViewModel) {
        self.appVM = appVM
    }

    var allFriends: [Friend] {
        onlineFriends + offlineFriends
    }

    var friendsInPrivate: [Friend] {
        friendsLocations.first(where: { $0.location == .private })?.friends ?? []
    }

    func getFriend(id: Friend.ID) -> Friend? {
        allFriends.first { $0.id == id }
    }

    var recentlyFriends: [Friend] {
        guard let appVM = appVM, let user = appVM.user else { return [] }
        return user.friends.reversed().compactMap { id in
            onlineFriends.first { $0.id == id } ?? offlineFriends.first { $0.id == id }
        }
    }

    var visibleFriendsLocations: [FriendsLocation] {
        friendsLocations.filter(\.location.isVisible)
    }

    func fetchAllFriends(errorHandler: @escaping (_ error: any Error) -> Void) async {
        isCacheCorrupted = false
        defer { isFetchingAllFriends = false }
        isFetchingAllFriends = true
        guard let appVM = appVM else {
            errorHandler(ApplicationError.appVMIsNotSetError)
            return
        }
        do {
            guard let user = appVM.user else { throw ApplicationError.userIsNotSetError }
            async let onlineFriendsTask = appVM.services.friendService.fetchFriends(
                count: user.onlineFriends.count + user.activeFriends.count,
                offline: false
            )
            async let offlineFriendsTask = appVM.services.friendService.fetchFriends(
                count: user.offlineFriends.count,
                offline: true
            )
            onlineFriends = try await onlineFriendsTask
            offlineFriends = try await offlineFriendsTask
            
            try processFriendListChanges()
        } catch {
            if error is DecodingError {
                self.isCacheCorrupted = true
            } else {
                errorHandler(error)
            }
            return
        }
        friendsLocations = await appVM.services.friendService.friendsGroupedByLocation(onlineFriends)
        applyFilters()
    }

    private func saveFriendsLocally(_ friends: [Friend]) {
        FriendCacheManager.saveFriends(friends)
    }
    
    private func loadFriendsFromLocal() throws -> [Friend] {
        return try FriendCacheManager.loadFriends()
    }

    private func processFriendListChanges() throws {
        let oldFriends = try loadFriendsFromLocal()
        let newFriends = self.allFriends

        guard !oldFriends.isEmpty else {
            saveFriendsLocally(newFriends)
            return
        }

        let oldFriendsDict = Dictionary(uniqueKeysWithValues: oldFriends.map { ($0.id, $0) })
        let newFriendsDict = Dictionary(uniqueKeysWithValues: newFriends.map { ($0.id, $0) })

        let oldIDs = Set(oldFriendsDict.keys)
        let newIDs = Set(newFriendsDict.keys)

        for id in newIDs.subtracting(oldIDs) {
            if newFriendsDict[id] != nil {
                historyVM.saveHistory(event: .newFriend, for: id)
            }
        }

        for id in oldIDs.subtracting(newIDs) {
            if oldFriendsDict[id] != nil {
                historyVM.saveHistory(event: .unfriend, for: id)
            }
        }

        for id in newIDs.intersection(oldIDs) {
            guard let oldFriend = oldFriendsDict[id], let newFriend = newFriendsDict[id] else { continue }

            if oldFriend.displayName != newFriend.displayName {
                historyVM.saveHistory(event: .displayNameChanged(from: oldFriend.displayName, to: newFriend.displayName), for: id)
            }
            if oldFriend.trustRank != newFriend.trustRank {
                historyVM.saveHistory(event: .trustRankChanged(from: oldFriend.trustRank.description, to: newFriend.trustRank.description), for: id)
            }
        }

        saveFriendsLocally(newFriends)
    }

    var isContentUnavailable: Bool {
        friendsLocations.isEmpty && !isFetchingAllFriends
    }
    
    convenience init(appVM: AppViewModel) {
        self.init()
        setAppVM(appVM)
    }
}
