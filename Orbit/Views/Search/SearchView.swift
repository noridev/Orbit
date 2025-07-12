//
//  SearchView.swift
//  Orbit
//
//  Created by NoriDev on 7/6/25.
//

import SwiftUI
import VRCKit

struct SearchView: View {
    @Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    
    @StateObject private var searchVM: SearchViewModel
    @State private var selected: String?
    
    init() {
        _searchVM = StateObject(wrappedValue: SearchViewModel(appVM: AppViewModel()))
    }
    
    var body: some View {
        NavigationSplitView {
            ZStack {
                // 그라데이션 배경
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.indigo.opacity(0.08),
                        Color.purple.opacity(0.05),
                        Color.clear
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                UserListView(selected: $selected, searchVM: searchVM)
            }
            .navigationTitle("Search")
        } detail: {
            ZStack {
                // 그라데이션 배경
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.mint.opacity(0.08),
                        Color.cyan.opacity(0.05),
                        Color.clear
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                UserDetailContainerView(selected: $selected)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(text: $searchVM.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .onSubmit(of: .search) {
            Task {
                await searchVM.searchUsers()
            }
        }
        .onAppear {
            searchVM.appVM = appVM
            searchVM.setFriendVM(friendVM)
        }
    }
}

private struct UserListView: View {
    @Binding var selected: String?
    @ObservedObject var searchVM: SearchViewModel
    @Environment(\.isSearching) private var isSearching

    var body: some View {
        List(searchVM.users, selection: $selected) { user in
            NavigationLabel {
                HStack {
                    UserIcon(
                        user: user,
                        size: Constants.IconSize.userDetailThumbnail
                    )

                    VStack(alignment: .leading) {
                        Text(user.displayName)
                            .font(.headline)
                        
                        if user.isFriend, let friend = searchVM.getFriendInfo(for: user.id) {
                            FriendStatusView(friend: friend)
                        } else if !user.statusDescription.isEmpty {
                            Text(user.statusDescription)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.leading, 4)
                }
            }
            .tag(user.id)
            .onAppear {
                if user.id == searchVM.users.last?.id {
                    Task {
                        await searchVM.loadMoreUsers()
                    }
                }
            }
        }
        .refreshable {
            if !searchVM.searchText.isEmpty {
                await searchVM.searchUsers()
            }
        }
        .overlay {
            if searchVM.isSearching && searchVM.users.isEmpty {
                ProgressView()
                    .padding(32)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            } else if searchVM.didSearch && searchVM.users.isEmpty {
                ContentUnavailableView.search
            } else if !searchVM.didSearch {
                ContentUnavailableView {
                    Label("Search for Users", systemImage: "magnifyingglass")
                } description: {
                    Text("Find users by their display name.")
                }
            }
        }
        .onChange(of: isSearching) {
            if !isSearching {
                searchVM.clearAndReset()
            }
        }
    }
}

private struct UserDetailContainerView: View {
    @Binding var selected: String?
    
    var body: some View {
        NavigationStack {
            if let selected = selected {
                UserDetailPresentationView(id: selected)
            } else {
                ContentUnavailableView {
                    Label("Select a User", systemImage: "person.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    let appVM = AppViewModel(isPreviewMode: true)
    return SearchView()
        .environment(appVM)
}
