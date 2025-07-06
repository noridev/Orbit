//
//  FriendsListView.swift
//  Orbit
//
//  Created by makinosp on 2024/09/16.
//

import MemberwiseInit
import SwiftUI
import VRCKit

@MemberwiseInit
struct FriendsListView: View {
    @Environment(\.isSearching) private var isSearching
    @Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    @Environment(FavoriteViewModel.self) var favoriteVM
    @InitWrapper(.internal, default: Binding<String?>.constant(nil), type: Binding<String?>.self)
    @Binding var selected: String?
    @State var isPresentedSheet = false

    var body: some View {
        @Bindable var friendVM = friendVM

        List(friendVM.filterResultFriends, selection: $selected) { friend in
            NavigationLabel {
                HStack {
                    UserIcon(user: friend, size: Constants.IconSize.userDetailThumbnail)

                    VStack(alignment: .leading) {
                        Text(friend.displayName)
                            .font(.headline)
                        
                        statusView(for: friend)
                    }
                    .padding(.leading, 4)
                }
            }
        }
        .sheet(isPresented: $isPresentedSheet) {
            FilterSheetView(
                sortType: $friendVM.sortType,
                statusFilter: $friendVM.filterUserStatus,
                favoriteGroupFilter: $friendVM.filterFavoriteGroups,
                eventFilter: .constant([]),
                sortContext: .friends,
                visibleSections: [.status, .favoriteGroup]
            )
            .presentationDetents([.medium])
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
        .onChange(of: friendVM.sortType) {
            friendVM.applyFilters()
        }
        .onChange(of: friendVM.filterUserStatus) {
            friendVM.applyFilters()
        }
        .onChange(of: friendVM.filterFavoriteGroups) {
            friendVM.applyFilters()
        }
    }

    @ViewBuilder
    private func statusView(for friend: Friend) -> some View {
        if !friend.statusDescription.isEmpty {
            Text(friend.statusDescription)
                .font(.caption)
                .foregroundColor(.gray)
        } else if let lastLogin = friend.lastLogin {
            HStack(spacing: 2) {
                Text("Last Login" + ":")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text(lastLogin.formatted(date: .numeric, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }

    @ViewBuilder private var overlayView: some View {
        if isProcessing {
            ProgressView()
                .padding(32)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
