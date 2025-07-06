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
    
    @StateObject private var searchVM: SearchViewModel
    @State private var selected: String?
    
    init() {
        _searchVM = StateObject(wrappedValue: SearchViewModel(appVM: AppViewModel()))
    }
    
    var body: some View {
        NavigationSplitView {
            UserListView(selected: $selected, searchVM: searchVM)
                .navigationTitle("Search")
        } detail: {
            UserDetailContainerView(selected: $selected)
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
                    // 친구가 아니어도 해당 사용자의 상태를 확인할 수 있으므로 UserIcon을 사용한 코드도 남겨둠.
                    //UserIcon(user: user, size: Constants.IconSize.userDetailThumbnail)

                    VStack(alignment: .leading) {
                        Text(user.displayName)
                            .font(.headline)
                        Text(user.statusDescription)
                            .font(.caption)
                            .foregroundColor(.gray)
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
            await searchVM.searchUsers()
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
                    Text("Find VRChat users by their display name.")
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
