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

        ScrollView {
            LazyVStack(spacing: 12) {
                if friendVM.isContentUnavailable {
                    emptyStateView
                } else {
                    ForEach(friendVM.filterResultFriends, id: \.id) { friend in
                        FriendCardView(friend: friend, selected: $selected)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .sheet(isPresented: $isPresentedSheet) {
            FilterSheetView(
                sortType: $friendVM.sortType,
                statusFilter: $friendVM.filterUserStatus,
                favoriteGroupFilter: $friendVM.filterFavoriteGroups,
                eventFilter: .constant([]),
                excludeWebUsers: $friendVM.excludeWebUsers,
                sortContext: .friends,
                visibleSections: [.status, .favoriteGroup, .platform]
            )
            .presentationDetents([.medium])
        }
        .overlay {
            if friendVM.isFetchingAllFriends && friendVM.filterResultFriends.isEmpty {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(32)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .refreshable {
            await friendVM.fetchAllFriends { error in
                appVM.handleError(error)
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
                            gradient: Gradient(colors: [Color.green.opacity(0.2), Color.blue.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: IconSet.friends.systemName)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                Text("친구가 없습니다")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("아직 친구를 추가하지 않았거나 모든 친구가 오프라인 상태입니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FriendCardView: View {
    let friend: Friend
    @Binding var selected: String?
    
    var body: some View {
        NavigationLink(value: friend.id) {
            HStack(spacing: 16) {
                // 프로필 이미지
                UserIcon(user: friend, size: Constants.IconSize.userDetailThumbnail)
                
                // 친구 정보
                VStack(alignment: .leading, spacing: 6) {
                    Text(friend.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    FriendStatusView(friend: friend)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 화살표
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.green.opacity(selected == friend.id ? 0.3 : 0.1),
                                        Color.blue.opacity(selected == friend.id ? 0.2 : 0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: selected == friend.id ? 2 : 1
                            )
                    }
                    .shadow(
                        color: selected == friend.id ? Color.green.opacity(0.2) : Color.black.opacity(0.05),
                        radius: selected == friend.id ? 8 : 4,
                        x: 0,
                        y: selected == friend.id ? 4 : 2
                    )
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: selected == friend.id)
        .simultaneousGesture(
            TapGesture().onEnded {
                selected = friend.id
            }
        )
    }
}
