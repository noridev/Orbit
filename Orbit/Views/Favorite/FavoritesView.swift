//
//  FavoritesView.swift
//  Orbit
//
//  Created by makinosp on 2024/03/16.
//

import SwiftUI
import VRCKit

struct FavoritesView: View {
    @Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    @Environment(FavoriteViewModel.self) var favoriteVM
    @State private var selected: SegmentIdSelection?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var segment: FavoriteViewSegment?
    @State private var isPresentedFavoriteGroups = false

    var body: some View {
        @Bindable var favoriteVM = favoriteVM
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ZStack {
                // 그라데이션 배경
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.pink.opacity(0.08),
                        Color.purple.opacity(0.05),
                        Color.clear
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if !isFetching && !isSelectedEmpty {
                            if segment != .world {
                                favoriteFriends
                            }
                            if segment != .friends {
                                favoriteWorlds
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                .overlay {
                    if isFetching {
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding(32)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    } else if isSelectedEmpty {
                        emptyStateView
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbarTitleMenu { toolbarTitleMenu }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            isPresentedFavoriteGroups = true
                        } label: {
                            Label("Edit", systemImage: IconSet.edit.systemName)
                        }
                    } label: {
                        IconSet.dots.icon
                    }
                }
            }
        } detail: { detail }
        .navigationSplitViewStyle(.balanced)
        .tint(Color(UIColor { $0.userInterfaceStyle == .dark ? .white : .black }))
        .refreshable {
            segment = .none
            await fetchFavoriteAction()
        }
        .sheet(isPresented: $isPresentedFavoriteGroups) {
            NavigationStack {
                FavoriteGroupsListView()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 80)
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.pink.opacity(0.2), Color.purple.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: IconSet.favorite.systemName)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.pink)
            }
            
            VStack(spacing: 8) {
                Text("즐겨찾기가 없습니다")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("아직 즐겨찾기에 추가한 친구나 월드가 없습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var isFetching: Bool {
        friendVM.isFetchingAllFriends || favoriteVM.isFetchingFavoriteFriends
    }

    @ViewBuilder private var toolbarTitleMenu: some View {
        Picker("", selection: $segment) {
            Label("All", systemImage: IconSet.favoriteSquares.systemName)
                .tag(Optional<FavoriteViewSegment>.none)
            ForEach(FavoriteViewSegment.allCases) { segment in
                Label(segment.description, systemImage: segment.icon.systemName)
                    .tag(segment)
            }
        }
    }

    private var detail: some View {
        NavigationStack {
            Group {
                if let selectedContainer = selected {
                    switch selectedContainer.segment {
                    case .friends:
                        UserDetailPresentationView(id: selectedContainer.selected.id)
                            .id(selectedContainer.id)
                    case .world:
                        WorldPresentationView(id: selectedContainer.selected.id)
                            .id(selectedContainer.id)
                    }
                } else {
                    ContentUnavailableView {
                        Label("Select an item", systemImage: IconSet.favorite.systemName)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    var favoriteFriends: some View {
        VStack(spacing: 16) {
            // 섹션 헤더
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green.opacity(0.2), Color.blue.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: IconSet.friends.systemName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.green)
                }
                
                Text("친구")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // 친구 그룹들
            let groups = favoriteVM.favoriteGroups(.friend)
            ForEach(groups) { group in
                let friends = favoriteVM.getFavoriteFriends(group.id)
                FriendGroupCard(
                    title: group.displayName,
                    friends: friends ?? [],
                    selected: $selected
                )
            }
        }
    }

    private var favoriteWorlds: some View {
        VStack(spacing: 16) {
            // 섹션 헤더
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.2), Color.pink.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "globe")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.purple)
                }
                
                Text("월드")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // 월드 그룹들
            ForEach(favoriteVM.favoriteWorldGroups) { favoriteWorlds in
                if let group = favoriteWorlds.group {
                    WorldGroupCard(
                        title: group.displayName,
                        favoriteWorlds: favoriteWorlds,
                        selected: $selected
                    )
                }
            }
        }
    }

    private var isSelectedEmpty: Bool {
        switch segment {
        case .friends:
            favoriteVM.favoriteGroups(.friend).isEmpty
        case .world:
            favoriteVM.favoriteWorldGroups.isEmpty
        case .none:
            favoriteVM.favoriteGroups(.friend).isEmpty && favoriteVM.favoriteWorldGroups.isEmpty
        }
    }

    private func fetchFavoriteAction() async {
        do {
            try await favoriteVM.fetchFavoriteFriends(
                service: appVM.services.favoriteService
            ) { favorite in
                friendVM.getFriend(id: favorite.favoriteId)
            }
            friendVM.favoriteFriends = favoriteVM.favoriteFriends
        } catch {
            appVM.handleError(error)
        }
    }
}

// MARK: - Friend Group Card
private struct FriendGroupCard: View {
    let title: String
    let friends: [Friend]
    @Binding var selected: SegmentIdSelection?
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 그룹 헤더
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("\(friends.count) / \(Constants.MaxCountInFavoriteList.friends.description)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(20)
            }
            .buttonStyle(.plain)
            
            // 친구 목록
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(friends) { friend in
                        FriendRowView(friend: friend, selected: $selected)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.green.opacity(0.1),
                                    Color.blue.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Friend Row View
private struct FriendRowView: View {
    let friend: Friend
    @Binding var selected: SegmentIdSelection?
    
    var body: some View {
        Button {
            selected = SegmentIdSelection(friendId: friend.id)
        } label: {
            HStack(spacing: 12) {
                UserIcon(user: friend, size: Constants.IconSize.userDetailThumbnail)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    FriendStatusView(friend: friend)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.3))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green.opacity(0.3), Color.blue.opacity(0.2)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: selected?.selected.id == friend.id ? 2 : 0
                            )
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - World Group Card
private struct WorldGroupCard: View {
    let title: String
    let favoriteWorlds: FavoriteWorldGroup
    @Binding var selected: SegmentIdSelection?
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 그룹 헤더
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("\(favoriteWorlds.worlds.count) / \(Constants.MaxCountInFavoriteList.world.description)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(20)
            }
            .buttonStyle(.plain)
            
            // 월드 목록
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(favoriteWorlds.worlds) { world in
                        WorldRowView(world: world, selected: $selected)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.1),
                                    Color.pink.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - World Row View
private struct WorldRowView: View {
    let world: FavoriteWorld
    @Binding var selected: SegmentIdSelection?
    
    var body: some View {
        Button {
            selected = SegmentIdSelection(worldId: world.id)
        } label: {
            HStack(spacing: 12) {
                GradientOverlayImageView(
                    imageUrl: world.imageUrl(.x512),
                    thumbnailImageUrl: world.imageUrl(.x256),
                    size: CGSize(width: 60, height: 60)
                )
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(world.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(world.authorName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.3))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.2)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: selected?.selected.id == world.id ? 2 : 0
                            )
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PreviewContainer {
        FavoritesView()
    }
}
