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

struct UserDetailJsonDetailView: View {
    let userDetail: UserDetail
    @State private var jsonString: String = "Generating JSON..."
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TextEditor(text: .constant(jsonString))
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, 8)
                .navigationTitle(userDetail.displayName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .onAppear(perform: generateJsonString)
        }
    }

    private func generateJsonString() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
            encoder.dateEncodingStrategy = .formatted(.iso8601Full)

            let data = try encoder.encode(userDetail)
            var finalJsonString = String(data: data, encoding: .utf8) ?? "Error: Could not convert JSON data to text."
            
            let pattern = "\\[\\s*\\]"
            finalJsonString = finalJsonString.replacingOccurrences(of: pattern, with: "[]", options: .regularExpression)
            
            self.jsonString = finalJsonString
        } catch {
            self.jsonString = "Error encoding user detail data to JSON: \(error.localizedDescription)"
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
    @State private var excludeWebUsers: Bool = false
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
        
        let platformFiltered = favoriteGroupFiltered.filter { friend in
            !excludeWebUsers || friend.platform != .web
        }

        return platformFiltered.sorted {
            switch sortType {
            case .name: $0.displayName.lowercased() < $1.displayName.lowercased()
            case .status: $0.status.rawValue < $1.status.rawValue
            case .latestLogin: $0.lastLogin ?? .distantPast > $1.lastLogin ?? .distantPast
            case .oldestLogin: $0.lastLogin ?? .distantFuture < $1.lastLogin ?? .distantFuture
            case .latestActivity: $0.lastActivity ?? .distantPast > $1.lastActivity ?? .distantPast
            case .oldestActivity: $0.lastActivity ?? .distantFuture < $1.lastActivity ?? .distantFuture
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
                        Text("Go to the Friends tab and pull down to refresh to regenerate the cache.")
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
                Button(action: loadCacheFromFile) {
                    Image(systemName: "arrow.clockwise")
                }
                Button(action: { isPresentedSheet.toggle() }) {
                    Image(systemName: IconSet.dots.systemName)
                }
            }
        }
        .sheet(isPresented: $isPresentedSheet, onDismiss: saveSettings) {
            FilterSheetView(
                sortType: $sortType,
                statusFilter: $filterUserStatus,
                favoriteGroupFilter: $filterFavoriteGroups,
                eventFilter: .constant([]),
                excludeWebUsers: $excludeWebUsers,
                sortContext: .friends,
                visibleSections: [.status, .favoriteGroup, .platform]
            )
            .presentationDetents([.medium])
        }
        .onAppear {
            loadCacheFromFile()
            loadSettings()
        }
        .alert("Cache corrupted", isPresented: $showCorruptedCacheAlert) {
            Button("Delete", role: .destructive) {
                FriendCacheManager.deleteCache()
                loadCacheFromFile()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The Friend Cache file is corrupted and cannot be read. Do you want to delete it?")
        }
    }

    private func loadCacheFromFile() {
        self.showCorruptedCacheAlert = false
        do {
            let loadedFriends = try FriendCacheManager.loadFriends()
            if loadedFriends.isEmpty {
                self.statusMessage = "Friend Cache file is empty or not found."
                self.friendsInCache = []
            } else {
                self.friendsInCache = loadedFriends
                self.statusMessage = ""
            }
        } catch {
            self.showCorruptedCacheAlert = true
            self.statusMessage = "Friend Cache file is corrupted."
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
        
        self.excludeWebUsers = defaults.bool(forKey: "raw_history_exclude_web_users")
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(self.sortType.rawValue, forKey: "raw_history_sort_type")
        
        let statusRawValues = self.filterUserStatus.map { $0.rawValue }
        defaults.set(statusRawValues, forKey: "raw_history_filter_user_status")
        
        let groupIDs = Array(self.filterFavoriteGroups)
        defaults.set(groupIDs, forKey: "raw_history_filter_favorite_groups")
        
        defaults.set(self.excludeWebUsers, forKey: "raw_history_exclude_web_users")
    }
}

#Preview {
    NavigationView {
        RawHistoryDataView()
    }
}
