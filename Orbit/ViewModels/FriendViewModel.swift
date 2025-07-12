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
    var excludeWebUsers: Bool = false
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
        self.excludeWebUsers = UserDefaults.standard.bool(forKey: Constants.Keys.excludeWebUsers.rawValue)
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
        defer { 
            isFetchingAllFriends = false
            applyFilters()
        }
        isFetchingAllFriends = true
        guard let appVM = appVM else {
            errorHandler(ApplicationError.appVMIsNotSetError)
            return
        }
        do {
            guard let user = appVM.user else { 
                print("ℹ️ [fetchAllFriends] User is not set, likely due to logout. Skipping fetch.")
                return 
            }
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
    }

    private func saveFriendsLocally(_ friends: [Friend]) {
        FriendCacheManager.saveFriends(friends)
    }
    
    private func loadFriendsFromLocal() throws -> [Friend] {
        return try FriendCacheManager.loadFriends()
    }

    private func processFriendListChanges() throws {
        print("🔄 [processFriendListChanges] Starting friend list change processing")
        
        let oldFriends = try loadFriendsFromLocal()
        let newFriends = self.allFriends

        print("🔄 [processFriendListChanges] Old friends count: \(oldFriends.count)")
        print("🔄 [processFriendListChanges] New friends count: \(newFriends.count)")

        guard !oldFriends.isEmpty else {
            print("🔄 [processFriendListChanges] No old friends data, saving new friends and skipping change detection")
            saveFriendsLocally(newFriends)
            return
        }

        let oldFriendsDict = Dictionary(uniqueKeysWithValues: oldFriends.map { ($0.id, $0) })
        let newFriendsDict = Dictionary(uniqueKeysWithValues: newFriends.map { ($0.id, $0) })

        let oldIDs = Set(oldFriendsDict.keys)
        let newIDs = Set(newFriendsDict.keys)

        print("🔄 [processFriendListChanges] Old friend IDs count: \(oldIDs.count)")
        print("🔄 [processFriendListChanges] New friend IDs count: \(newIDs.count)")

        let addedIDs = newIDs.subtracting(oldIDs)
        print("🔄 [processFriendListChanges] Added friends: \(addedIDs.count)")
        for id in addedIDs {
            if let newFriend = newFriendsDict[id] {
                print("➕ [processFriendListChanges] New friend: \(newFriend.displayName) (ID: \(id))")
                historyVM.saveHistory(event: .newFriend, for: id)
            }
        }

        let removedIDs = oldIDs.subtracting(newIDs)
        print("🔄 [processFriendListChanges] Removed friends: \(removedIDs.count)")
        for id in removedIDs {
            if let oldFriend = oldFriendsDict[id] {
                print("➖ [processFriendListChanges] Removed friend: \(oldFriend.displayName) (ID: \(id))")
                historyVM.saveHistory(event: .unfriend, for: id)
            }
        }

        let commonIDs = newIDs.intersection(oldIDs)
        print("🔄 [processFriendListChanges] Common friends to check for changes: \(commonIDs.count)")
        
        var changedCount = 0
        for id in commonIDs {
            guard let oldFriend = oldFriendsDict[id], let newFriend = newFriendsDict[id] else { continue }

            if oldFriend.displayName != newFriend.displayName {
                print("📝 [processFriendListChanges] Name changed for \(id): \(oldFriend.displayName) → \(newFriend.displayName)")
                historyVM.saveHistory(event: .displayNameChanged(from: oldFriend.displayName, to: newFriend.displayName), for: id)
                changedCount += 1
            }
            if oldFriend.trustRank != newFriend.trustRank {
                print("🛡️ [processFriendListChanges] Trust rank changed for \(id): \(oldFriend.trustRank.description) → \(newFriend.trustRank.description)")
                historyVM.saveHistory(event: .trustRankChanged(from: oldFriend.trustRank.description, to: newFriend.trustRank.description), for: id)
                changedCount += 1
            }
        }
        
        print("🔄 [processFriendListChanges] Total changes recorded: \(changedCount)")

        saveFriendsLocally(newFriends)
        print("✅ [processFriendListChanges] Friend list processing completed")
    }

    var isContentUnavailable: Bool {
        friendsLocations.isEmpty && !isFetchingAllFriends
    }
    
    convenience init(appVM: AppViewModel) {
        self.init()
        setAppVM(appVM)
    }
}
