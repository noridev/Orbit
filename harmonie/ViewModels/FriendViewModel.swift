//
//  FriendViewModel.swift
//  Harmonie
//
//  Created by makinosp on 2024/06/09.
//

import Observation
import VRCKit

@MainActor @Observable
class FriendViewModel {
    var onlineFriends: [Friend] = []
    var offlineFriends: [Friend] = []
    var friendsLocations: [FriendsLocation] = []
    var filterUserStatus: Set<UserStatus> = []
    var filterFavoriteGroups: Set<FavoriteGroup> = []
    var filterText: String = ""
    var sortType: SortType = .default
    var sortOrder: SortOrder = .asc
    var isRequesting = true
    @ObservationIgnored let user: User
    @ObservationIgnored private let service: any FriendServiceProtocol

    init(user: User, service: any FriendServiceProtocol) {
        self.user = user
        self.service = service
    }

    var allFriends: [Friend] {
        onlineFriends + offlineFriends
    }

    func getFriend(id: String) -> Friend? {
        allFriends.first { $0.id == id }
    }

    /// Returns a list of matches for either `onlineFriends` or `offlineFriends`
    /// for each id of reversed order friend list.
    /// - Returns a list of recentry friends
    var recentlyFriends: [Friend] {
        user.friends.reversed().compactMap { id in
            onlineFriends.first { $0.id == id } ?? offlineFriends.first { $0.id == id }
        }
    }

    /// Fetch friends from API
    func fetchAllFriends() async throws {
        async let onlineFriendsTask = service.fetchFriends(
            count: user.onlineFriends.count + user.activeFriends.count,
            offline: false
        )
        async let offlineFriendsTask = service.fetchFriends(
            count: user.offlineFriends.count,
            offline: true
        )
        onlineFriends = try await onlineFriendsTask
        offlineFriends = try await offlineFriendsTask
        friendsLocations = service.friendsGroupedByLocation(onlineFriends)
    }
}
