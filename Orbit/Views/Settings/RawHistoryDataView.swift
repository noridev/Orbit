//
//  RawHistoryDataView.swift
//  Orbit
//
//  Created by NoriDev on 7/6/25.
//

import SwiftUI
import VRCKit

struct FriendJsonDetailView: View {
    let friend: Friend
    @State private var jsonString: String = "Generating JSON..."

    var body: some View {
        TextEditor(text: .constant(jsonString))
            .font(.system(size: 12, design: .monospaced))
            .padding(.horizontal, 8)
            .navigationTitle(friend.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: generateJsonString)
    }

    private func generateJsonString() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
            encoder.dateEncodingStrategy = .formatted(.iso8601Full)

            let data = try encoder.encode(friend)
            var finalJsonString = String(data: data, encoding: .utf8) ?? "Error: Could not convert JSON data to text."
            
            let pattern = "\\[\\s*\\]"
            finalJsonString = finalJsonString.replacingOccurrences(of: pattern, with: "[]", options: .regularExpression)
            
            self.jsonString = finalJsonString
        } catch {
            self.jsonString = "Error encoding friend data to JSON: \(error.localizedDescription)"
        }
    }
}

struct RawHistoryDataView: View {
    @Environment(FavoriteViewModel.self) private var favoriteVM
    @State private var friendsInCache: [Friend] = []
    @State private var statusMessage: String = ""
    @State private var searchText: String = ""
    @State private var isPresentedSheet = false
    @State private var sortType: SortType = .name
    @State private var filterUserStatus: Set<UserStatus> = []
    @State private var filterFavoriteGroups: Set<FavoriteGroup.ID> = []
    @State private var showCorruptedCacheAlert = false

    private var filteredFriends: [Friend] {
        let searched = friendsInCache.filter {
            searchText.isEmpty || $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
        
        let statusFiltered = searched.filter {
            filterUserStatus.isEmpty || filterUserStatus.contains($0.status)
        }
        
        let favoriteGroupFiltered = statusFiltered.filter { friend in
            filterFavoriteGroups.isEmpty || isFriendInFavoriteGroups(friend: friend)
        }

        return favoriteGroupFiltered.sorted {
            switch sortType {
            case .name: $0.displayName.lowercased() < $1.displayName.lowercased()
            case .loginLatest: $0.lastLogin ?? .distantPast > $1.lastLogin ?? .distantPast
            case .loginOldest: $0.lastLogin ?? .distantFuture < $1.lastLogin ?? .distantFuture
            case .status: $0.status.rawValue < $1.status.rawValue
            default: $0.displayName.lowercased() < $1.displayName.lowercased()
            }
        }
    }
    
    private func isFriendInFavoriteGroups(friend: Friend) -> Bool {
        return filterFavoriteGroups.contains { groupId in
            favoriteVM.getFavoriteFriends(groupId)?.contains(where: { $0.id == friend.id }) ?? false
        }
    }

    var body: some View {
        VStack {
            if !statusMessage.isEmpty {
                VStack(spacing: 20) {
                    Text(statusMessage)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    if showCorruptedCacheAlert {
                        Text("친구 목록 탭으로 이동하여 아래로 당겨 새로고침하면 캐시가 재생성됩니다.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            } else {
                List(filteredFriends) { friend in
                    NavigationLink(destination: FriendJsonDetailView(friend: friend)) {
                        HStack(spacing: 12) {
                            UserIcon(user: friend, size: Constants.IconSize.userDetailThumbnail)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(friend.displayName)
                                    .font(.headline)
                                HStack {
                                    HStack(spacing: 3) {
                                        IconSet.shield.icon
                                        Text(friend.trustRank.description)
                                    }
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .foregroundStyle(.white)
                                    .background(friend.trustRank.color.opacity(0.5))
                                    .background(.thinMaterial)
                                    .clipShape(Capsule())
                                    Spacer()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Friend Cache Inspector")
        .searchable(text: $searchText, prompt: "Search by name")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { isPresentedSheet.toggle() }) {
                    Image(systemName: IconSet.dots.systemName)
                }
                Button(action: loadCacheFromFile) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .sheet(isPresented: $isPresentedSheet, onDismiss: saveSettings) {
            FilterSheetView(
                sortType: $sortType,
                statusFilter: $filterUserStatus,
                favoriteGroupFilter: $filterFavoriteGroups,
                eventFilter: .constant([]),
                sortContext: .friends,
                visibleSections: [.status, .favoriteGroup]
            )
            .presentationDetents([.medium])
        }
        .onAppear {
            loadCacheFromFile()
            loadSettings()
        }
        .alert("캐시가 손상됨", isPresented: $showCorruptedCacheAlert) {
            Button("삭제", role: .destructive) {
                FriendCacheManager.deleteCache()
                loadCacheFromFile()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("캐시 파일이 손상되어 읽을 수 없습니다. 파일을 삭제하시겠습니까?")
        }
    }

    private func loadCacheFromFile() {
        self.showCorruptedCacheAlert = false
        do {
            let loadedFriends = try FriendCacheManager.loadFriends()
            if loadedFriends.isEmpty {
                self.statusMessage = "캐시 파일이 비어있거나 찾을 수 없습니다."
                self.friendsInCache = []
            } else {
                self.friendsInCache = loadedFriends
                self.statusMessage = ""
            }
        } catch {
            self.showCorruptedCacheAlert = true
            self.statusMessage = "캐시 파일이 손상되었습니다."
            self.friendsInCache = []
        }
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        if let rawSortType = defaults.string(forKey: "raw_history_sort_type"),
           let restoredSortType = SortType(rawValue: rawSortType) {
            self.sortType = restoredSortType
        }
        
        if let rawStatus = defaults.array(forKey: "raw_history_filter_user_status") as? [String] {
            self.filterUserStatus = Set(rawStatus.compactMap(UserStatus.init))
        }
        
        if let rawGroups = defaults.array(forKey: "raw_history_filter_favorite_groups") as? [String] {
            self.filterFavoriteGroups = Set(rawGroups)
        }
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(self.sortType.rawValue, forKey: "raw_history_sort_type")
        
        let statusRawValues = self.filterUserStatus.map { $0.rawValue }
        defaults.set(statusRawValues, forKey: "raw_history_filter_user_status")
        
        let groupIDs = Array(self.filterFavoriteGroups)
        defaults.set(groupIDs, forKey: "raw_history_filter_favorite_groups")
    }
}

#Preview {
    NavigationView {
        RawHistoryDataView()
    }
}
