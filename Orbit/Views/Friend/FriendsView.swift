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
            NavigationStack {
                ZStack {
                    // 그라데이션 배경
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.green.opacity(0.08),
                            Color.blue.opacity(0.05),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    FriendsListView(selected: $selected)
                }
                .navigationTitle("Friends")
                .navigationDestination(for: String.self) { friendId in
                    UserDetailPresentationView(id: friendId)
                }
            }
        } detail: { 
            ZStack {
                // 그라데이션 배경
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.08),
                        Color.pink.opacity(0.05),
                        Color.clear
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                detail
            }
        }
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
                    emptyDetailView
                }
            }
        }
    }
    
    private var emptyDetailView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple.opacity(0.2), Color.pink.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: IconSet.friends.systemName)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.purple)
            }
            
            VStack(spacing: 8) {
                Text("친구를 선택하세요")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("왼쪽에서 친구를 선택하여 자세한 정보를 확인하세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

#Preview {
    PreviewContainer {
        FriendsView()
    }
}
