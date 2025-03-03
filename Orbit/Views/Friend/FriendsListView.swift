//
//  FriendsListView.swift
//  Orbit
//
//  Created by makinosp on 2024/09/16.
//

import MemberwiseInit
import SwiftUI

@MemberwiseInit
struct FriendsListView: View {
    @Environment(\.isSearching) private var isSearching
    @Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    @Environment(FavoriteViewModel.self) var favoriteVM
    @InitWrapper(.internal, type: Binding<String?>)
    @Binding private var selected: String?

    var body: some View {
        List(friendVM.filterResultFriends, selection: $selected) { friend in
            NavigationLabel {
                HStack {
                    UserIcon(user: friend, size: Constants.IconSize.userDetailThumbnail)

                    VStack(alignment: .leading) {
                        Text(friend.displayName)
                            .font(.headline)

                        if !friend.statusDescription.isEmpty {
                            Text(friend.statusDescription)
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            HStack(spacing: 2) {
                                Text("Last Login" + ":")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                Text(friend.lastLogin.formatted(date: .numeric, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.leading, 4)
                }
            }
        }
        .overlay { overlayView }
        .toolbar { toolbarContent }
        .refreshable {
            await friendVM.fetchAllFriends { error in
                appVM.handleError(error)
            }
        }
        .onChange(of: isSearching) {
            if !isSearching {
                friendVM.filterText = ""
                friendVM.applyFilters()
            }
        }
    }

    @ViewBuilder private var overlayView: some View {
        if isProcessing {
            ProgressView()
        } else if friendVM.filterResultFriends.isEmpty {
            if friendVM.isEmptyAllFilters {
                ContentUnavailableView {
                    Label("No Friends", systemImage: IconSet.friends.systemName)
                        .foregroundColor(.gray)
                }
            } else {
                ContentUnavailableView.search
            }
        }
    }

    private var isProcessing: Bool {
        friendVM.isProcessingFilter || friendVM.isFetchingAllFriends
    }
}
