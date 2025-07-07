//
//  FriendViewModel+Filters.swift
//  Orbit
//
//  Created by makinosp on 2024/08/12.
//

import VRCKit

extension FriendViewModel {
    func clearFilters() {
        filterUserStatus = []
        filterFavoriteGroups = []
        excludeWebUsers = false
        applyFilters()
    }

    /// Filters the list of friends based on the specified list type.
    private var filteredFriends: [Friend] {
        recentlyFriends
            .filter { friend in
                filterFavoriteGroups.isEmpty ||
                isFriendContainedInFilterFavoriteGroups(friend: friend)
            }
            .filter {
                filterUserStatus.isEmpty || filterUserStatus.contains($0.status)
            }
            .filter {
                filterText.isEmpty || $0.displayName.range(of: filterText, options: .caseInsensitive) != nil
            }
            .filter { friend in
                !excludeWebUsers || friend.platform != .web
            }
            .sorted {
                switch sortType {
                case .name: $0.displayName < $1.displayName
                case .loginLatest: $0.lastLogin ?? .distantPast > $1.lastLogin ?? .distantPast
                case .loginOldest: $0.lastLogin ?? .distantFuture < $1.lastLogin ?? .distantFuture
                case .status: $0.status.rawValue < $1.status.rawValue
                default: $0.lastLogin ?? .distantPast > $1.lastLogin ?? .distantPast
                }
            }
    }

    func applyFilters() {
        isProcessingFilter = true
        Task {
            defer { isProcessingFilter = false }
            filterResultFriends = filteredFriends
        }
    }

    var isEmptyAllFilters: Bool {
        [ filterUserStatus.isEmpty, filterFavoriteGroups.isEmpty, filterText.isEmpty, !excludeWebUsers ].allSatisfy(\.self)
    }

    private func isFriendContainedInFilterFavoriteGroups(friend: Friend) -> Bool {
        filterFavoriteGroups.contains { favoriteGroupId in
            guard let favoriteFriend = favoriteFriends.first(where: { favoriteFriend in
                favoriteFriend.favoriteGroupId == favoriteGroupId
            }) else {
                return true
            }
            return favoriteFriend.friends.contains(friend)
        }
    }
}
