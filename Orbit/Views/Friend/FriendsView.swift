//
//  FriendsView.swift
//  Orbit
//
//  Created by makinosp on 2024/03/03.
//

import SwiftUI
import VRCKit

struct FriendsView: View {
    @Environment(FriendViewModel.self) var friendVM
    @Environment(FavoriteViewModel.self) var favoriteVM
    @Environment(AppViewModel.self) var appVM
    @State private var selected: String?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        @Bindable var friendVM = friendVM
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FriendsListView(selected: $selected)
                .navigationTitle("Friends")
        } detail: { detail }
        .navigationSplitViewStyle(.balanced)
        .tint(Color(UIColor { $0.userInterfaceStyle == .dark ? .white : .black }))
        .searchable(
            text: $friendVM.filterText,
            placement: .navigationBarDrawer(displayMode: .automatic)
        )
        .onSubmit(of: .search) {
            friendVM.applyFilters()
        }
        .onAppear {
            Task {
                await friendVM.fetchAllFriends { error in
                    appVM.handleError(error)
                }
            }
        }
    }

    private var detail: some View {
        NavigationStack {
            Group {
                if let selected = selected {
                    UserDetailPresentationView(id: selected)
                } else {
                    ContentUnavailableView {
                        Label("Select a Friend", systemImage: IconSet.friends.systemName)
                            .foregroundColor(.gray)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    PreviewContainer {
        FriendsView()
    }
}
