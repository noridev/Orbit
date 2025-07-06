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
        if friend.status != .offline {
            if !friend.statusDescription.isEmpty {
                Text(friend.statusDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                InstanceLocationView(friend: friend)
            }
        } else {
            if let lastLogin = friend.lastLogin {
                LastLoginView(lastLogin: lastLogin)
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

struct InstanceLocationView: View {
    let friend: Friend
    @State private var instance: Instance?
    @State private var isLoading = true
    @State private var error = false
    @Environment(AppViewModel.self) var appVM

    var body: some View {
        Group {
            if isLoading {
                Text("위치 정보 로딩 중...")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else if error {
                Text("위치 정보를 가져올 수 없습니다")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else if let instance = instance {
                VStack(alignment: .leading, spacing: 2) {
                    Text(InstanceUtil.getWorldNameWithInstance(instance))
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(InstanceUtil.getInstanceTypeWithUserCount(instance))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                Text(locationDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            if isLoading {
                Task { await loadInstanceInfo() }
            }
        }
    }

    private var locationDescription: String {
        switch friend.location {
        case .private:
            String(localized: "Private")
        case .traveling:
            String(localized: "Traveling")
        case .offline:
            String(localized: "Offline")
        case .id:
            String(localized: "In world")
        }
    }

    private func loadInstanceInfo() async {
        guard case let .id(locationId) = friend.location else {
            isLoading = false
            return
        }
        do {
            let service = appVM.services.instanceService
            instance = try await service.fetchInstance(location: locationId)
            isLoading = false
        } catch {
            self.error = true
            isLoading = false
        }
    }
}

struct LastLoginView: View {
    let lastLogin: Date
    @State private var relativeTimeString = ""
    
    var body: some View {
        HStack(spacing: 2) {
            Text("Last Login" + ":")
                .font(.caption)
                .foregroundStyle(.gray)
            Text(relativeTimeString)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .task {
            await updateRelativeTime()
        }
        .onAppear {
            updateRelativeTimeSync()
        }
    }
    
    private func updateRelativeTimeSync() {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: lastLogin, to: now)
        
        if let day = components.day, day > 0 {
            relativeTimeString = lastLogin.formatted(date: .numeric, time: .shortened)
        } else {
            Task {
                await updateRelativeTime()
            }
        }
    }
    
    private func updateRelativeTime() async {
        let dateUtil = DateUtil.shared
        let relativeString = await dateUtil.formatRelative(from: lastLogin)
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: lastLogin, to: now)
        
        if let day = components.day, day == 0 {
            relativeTimeString = relativeString
        }
    }
}
