//
//  MainTabView.swift
//  Harmonie
//
//  Created by makinosp on 2024/06/19.
//

import SwiftUI
import VRCKit

struct MainTabView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var friendVM: FriendViewModel
    @EnvironmentObject var favoriteVM: FavoriteViewModel

    var body: some View {
        TabView {
            LocationsView(appVM: appVM)
                .tabItem {
                    Image(systemName: "location.fill")
                    Text("Locations")
                }
            FriendsView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }
            FavoritesView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Favorites")
                }
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .task {
            do {
                try await friendVM.fetchAllFriends()
                try await favoriteVM.fetchFavorite()
            } catch {
                appVM.handleError(error)
            }
        }
    }
}
