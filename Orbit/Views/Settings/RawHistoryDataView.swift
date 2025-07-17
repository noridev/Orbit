//
//  RawHistoryDataView.swift
//  Orbit
//
//  Created by NoriDev on 7/6/25.
//

import SwiftUI
import VRCKit
import UIKit

struct JsonDataUtils {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        encoder.dateEncodingStrategy = .formatted(.iso8601Full)
        return encoder
    }()
    
    static func normalizeJsonString(_ jsonString: String) -> String {
        let emptyArrayPattern = "\\[\\s*\\]"
        let emptyObjectPattern = "\\{\\s*\\}"
        var normalized = jsonString.replacingOccurrences(of: emptyArrayPattern, with: "[]", options: .regularExpression)
        normalized = normalized.replacingOccurrences(of: emptyObjectPattern, with: "{}", options: .regularExpression)
        return normalized
    }
    
    static func encodeToJsonString<T: Encodable>(_ data: T) throws -> String {
        let data = try encoder.encode(data)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "EncodingError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not convert JSON data to text"])
        }
        return normalizeJsonString(jsonString)
    }
    
    static func prettyPrintJsonData(_ rawData: Data) -> String {
        if let jsonObject = try? JSONSerialization.jsonObject(with: rawData),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]),
           let jsonString = String(data: prettyData, encoding: .utf8) {
            return normalizeJsonString(jsonString)
        } else {
            return String(data: rawData, encoding: .utf8) ?? "Error: Could not convert raw data to text."
        }
    }
}

struct LoadingStateManager {
    @MainActor
    static func startLoading(_ viewModel: JsonDataViewModel) {
        viewModel.isLoading = true
        viewModel.error = nil
    }
    
    @MainActor
    static func finishLoading(_ viewModel: JsonDataViewModel) {
        viewModel.isLoading = false
    }
    
    @MainActor
    static func handleError(_ viewModel: JsonDataViewModel, error: Error) {
        viewModel.error = error
        viewModel.isLoading = false
    }
}

struct LoadingMessageGenerator {
    static func generateMessage(isLocalDataView: Bool, useAPIData: Bool) -> String {
        if isLocalDataView {
            return useAPIData ? "Fetching Friend History..." : "Fetching Friend Cache..."
        } else {
            return useAPIData ? "Fetching VRChat API..." : "Fetching Friend Cache..."
        }
    }
}

struct ErrorDisplayView: View {
    let error: Error
    let title: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.red)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct UserDefaultsSettingsManager {
    static func loadSettings(
        sortType: inout SortType,
        filterUserStatus: inout Set<UserStatus>,
        filterFavoriteGroups: inout Set<FavoriteGroup.ID>,
        excludeWebUsers: inout Bool,
        prefix: String = "raw_history"
    ) {
        let defaults = UserDefaults.standard
        
        if let rawSortType = defaults.string(forKey: "\(prefix)_sort_type"),
           let restoredSortType = SortType(rawValue: rawSortType) {
            sortType = restoredSortType
        }
        
        if let rawStatus = defaults.array(forKey: "\(prefix)_filter_user_status") as? [String] {
            filterUserStatus = Set(rawStatus.compactMap(UserStatus.init))
        }
        
        if let rawGroups = defaults.array(forKey: "\(prefix)_filter_favorite_groups") as? [String] {
            filterFavoriteGroups = Set(rawGroups)
        }
        
        excludeWebUsers = defaults.bool(forKey: "\(prefix)_exclude_web_users")
    }
    
    static func saveSettings(
        sortType: SortType,
        filterUserStatus: Set<UserStatus>,
        filterFavoriteGroups: Set<FavoriteGroup.ID>,
        excludeWebUsers: Bool,
        prefix: String = "raw_history"
    ) {
        let defaults = UserDefaults.standard
        defaults.set(sortType.rawValue, forKey: "\(prefix)_sort_type")
        
        let statusRawValues = filterUserStatus.map { $0.rawValue }
        defaults.set(statusRawValues, forKey: "\(prefix)_filter_user_status")
        
        let groupIDs = Array(filterFavoriteGroups)
        defaults.set(groupIDs, forKey: "\(prefix)_filter_favorite_groups")
        
        defaults.set(excludeWebUsers, forKey: "\(prefix)_exclude_web_users")
    }
}

struct FriendListItemView: View {
    let friend: Friend

    var body: some View {
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

struct CacheLoadingUtils {
    @MainActor
    static func loadFriendsFromCache() -> (friends: [Friend], statusMessage: String, showCorruptedAlert: Bool) {
        do {
            let loadedFriends = try FriendCacheManager.loadFriends()
            if loadedFriends.isEmpty {
                return ([], "Friend Cache file is empty or not found.", false)
            } else {
                return (loadedFriends, "", false)
            }
        } catch {
            return ([], "Friend Cache file is corrupted.", true)
        }
    }
}

@MainActor
class JsonDataViewModel: ObservableObject {
    @Published var jsonString: String = "Loading..."
    @Published var isLoading = true
    @Published var error: Error?
    @Published var useAPIData = false
    
    private let userId: String
    private let cachedData: Any?
    var appVM: AppViewModel
    
    init(userId: String, cachedData: Any?, appVM: AppViewModel) {
        self.userId = userId
        self.cachedData = cachedData
        self.appVM = appVM
    }
    
    func loadData() {
        Task {
            await loadDataAsync()
        }
    }
    
    func loadDataAsync() async {
        LoadingStateManager.startLoading(self)
        
        if useAPIData {
            await loadAPIData()
        } else {
            await loadCachedData()
        }
    }
    
    func loadLocalData() {
        Task {
            await loadLocalDataAsync()
        }
    }
    
    func loadLocalDataAsync() async {
        LoadingStateManager.startLoading(self)
        
        await MainActor.run {
            let localData = FriendCacheManager.getUserLocalData(userId: userId)
            
            do {
                if useAPIData {
                    struct HistoryDataStruct: Codable {
                        let history: [FriendHistory]
                        let friendId: String
                        let exportDate: Date
                    }
                    
                    let historyData = HistoryDataStruct(
                        history: localData.history,
                        friendId: userId,
                        exportDate: Date()
                    )
                    
                    self.jsonString = try JsonDataUtils.encodeToJsonString(historyData)
                } else {
                    struct CacheDataStruct: Codable {
                        let friend: Friend?
                        let friendId: String
                        let exportDate: Date
                    }
                    
                    let cacheData = CacheDataStruct(
                        friend: localData.friend,
                        friendId: userId,
                        exportDate: Date()
                    )
                    
                    self.jsonString = try JsonDataUtils.encodeToJsonString(cacheData)
                }
                
                LoadingStateManager.finishLoading(self)
            } catch {
                LoadingStateManager.handleError(self, error: error)
                self.jsonString = "Error encoding local data: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadAPIData() async {
        do {
            // Check if this is a group request (groupId starts with "grp_")
            if userId.hasPrefix("grp_") {
                let rawData = try await appVM.services.groupService.fetchGroupRawJSON(groupId: userId)
                self.jsonString = JsonDataUtils.prettyPrintJsonData(rawData)
            } else {
                let rawData = try await appVM.services.userService.fetchUserRawJSON(userId: userId)
                self.jsonString = JsonDataUtils.prettyPrintJsonData(rawData)
            }
            LoadingStateManager.finishLoading(self)
        } catch {
            LoadingStateManager.handleError(self, error: error)
            self.jsonString = "Error loading data: \(error.localizedDescription)"
        }
    }
    
    private func loadCachedData() async {
        guard let cachedData = cachedData else {
            let error = NSError(domain: "CacheError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Cached data not available"])
            LoadingStateManager.handleError(self, error: error)
            self.jsonString = "Error loading data: \(error.localizedDescription)"
            return
        }
        
        do {
            if let encodableData = cachedData as? Encodable {
                self.jsonString = try JsonDataUtils.encodeToJsonString(encodableData)
                LoadingStateManager.finishLoading(self)
            } else {
                throw NSError(domain: "EncodingError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Data is not encodable"])
            }
        } catch {
            LoadingStateManager.handleError(self, error: error)
            self.jsonString = "Error loading data: \(error.localizedDescription)"
        }
    }
}

struct DataSourcePicker: View {
    @Binding var useAPIData: Bool
    let isLocalDataView: Bool
    
    var body: some View {
        HStack {
            Text("Data Source:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if isLocalDataView {
                Picker("Data Source", selection: $useAPIData) {
                    Text("Cache").tag(false)
                    Text("History").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
            } else {
                Picker("Data Source", selection: $useAPIData) {
                    Text("API").tag(true)
                    Text("Cache").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }
}

struct JsonContentView: View {
    let jsonString: String
    let isLoading: Bool
    let error: Error?
    let useAPIData: Bool
    let isLocalDataView: Bool

    var body: some View {
        if isLoading {
            ProgressView(LoadingMessageGenerator.generateMessage(isLocalDataView: isLocalDataView, useAPIData: useAPIData))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = error {
            ErrorDisplayView(error: error, title: "Error fetching data")
        } else {
            LargeTextView(text: jsonString)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 8)
        }
    }
}

struct JsonDetailView<Data: Any>: View {
    @Environment(AppViewModel.self) var appVM
    @StateObject private var viewModel: JsonDataViewModel
    let userId: String
    let cachedData: Data?
    let isLocalDataView: Bool
    let title: String
    let subTitle: String
    let useNavigationStack: Bool
    let showToolbar: Bool
    let onDismiss: (() -> Void)?
    
    init(
        userId: String,
        cachedData: Data?,
        isLocalDataView: Bool = false,
        title: String,
        subTitle: String,
        useNavigationStack: Bool = false,
        showToolbar: Bool = false,
        onDismiss: (() -> Void)? = nil
    ) {
        self.userId = userId
        self.cachedData = cachedData
        self.isLocalDataView = isLocalDataView
        self.title = title
        self.subTitle = subTitle
        self.useNavigationStack = useNavigationStack
        self.showToolbar = showToolbar
        self.onDismiss = onDismiss
        self._viewModel = StateObject(wrappedValue: JsonDataViewModel(userId: userId, cachedData: cachedData, appVM: AppViewModel()))
    }
    
    var body: some View {
        Group {
            if useNavigationStack {
                NavigationStack {
                    contentView
                }
            } else {
                contentView
            }
        }
    }
    
    private var contentView: some View {
        let content = VStack {
            DataSourcePicker(useAPIData: $viewModel.useAPIData, isLocalDataView: isLocalDataView)
            
            JsonContentView(
                jsonString: viewModel.jsonString,
                isLoading: viewModel.isLoading,
                error: viewModel.error,
                useAPIData: viewModel.useAPIData,
                isLocalDataView: isLocalDataView
            )
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showToolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss?()
                    }
                }
            }
        }
        .onAppear {
            viewModel.appVM = appVM
            if !isLocalDataView {
                viewModel.useAPIData = true
            }
            if isLocalDataView {
                viewModel.loadLocalData()
            } else {
                viewModel.loadData()
            }
        }
        .onChange(of: viewModel.useAPIData) { _, _ in
            if isLocalDataView {
                viewModel.loadLocalData()
            } else {
                viewModel.loadData()
            }
        }
        .refreshable {
            if isLocalDataView {
                await viewModel.loadLocalDataAsync()
            } else {
                await viewModel.loadDataAsync()
            }
        }
        
        if #available(iOS 26.0, *) {
            return content
                .navigationSubtitle(subTitle)
        } else {
            return content
        }
    }
}

struct FriendJsonDetailView: View {
    let friendId: String
    let cachedFriend: Friend?
    let isLocalDataView: Bool
    
    init(friendId: String, cachedFriend: Friend?, isLocalDataView: Bool = false) {
        self.friendId = friendId
        self.cachedFriend = cachedFriend
        self.isLocalDataView = isLocalDataView
    }
    
    var body: some View {
        JsonDetailView(
            userId: friendId,
            cachedData: cachedFriend,
            isLocalDataView: isLocalDataView,
            title: cachedFriend?.displayName ?? "Local Data",
            subTitle: "Local Data"
        )
    }
}

struct UserDetailJsonDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let userId: String
    let cachedUserDetail: UserDetail?
    let isLocalDataView: Bool

    init(userId: String, cachedUserDetail: UserDetail?, isLocalDataView: Bool = false) {
        self.userId = userId
        self.cachedUserDetail = cachedUserDetail
        self.isLocalDataView = isLocalDataView
    }

    var body: some View {
        JsonDetailView(
            userId: userId,
            cachedData: cachedUserDetail,
            isLocalDataView: isLocalDataView,
            title: cachedUserDetail?.displayName ?? "JSON Data",
            subTitle: "JSON Data",
            useNavigationStack: true,
            showToolbar: true,
            onDismiss: { dismiss() }
        )
    }
}

struct LargeTextView: UIViewRepresentable {
    let text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .clear
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.alwaysBounceVertical = true
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
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
    @State private var showAllDataView = false

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
                    NavigationLink(destination: FriendJsonDetailView(friendId: friend.id, cachedFriend: friend, isLocalDataView: true)) {
                        FriendListItemView(friend: friend)
                    }
                }
            }
        }
        .navigationTitle("Friend Cache Inspector")
        .searchable(text: $searchText, prompt: "Search by name")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { isPresentedSheet.toggle() }) {
                    Image(systemName: IconSet.filter.systemName)
                }
                
                Menu {
                    Button(action: loadCacheFromFile) {
                        Image(systemName: "arrow.clockwise")
                        Text("캐시 새로고침")
                    }
                    
                    Button("모든 데이터 표시", systemImage: "doc.text") {
                        showAllDataView = true
                    }
                } label: {
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
        .sheet(isPresented: $showAllDataView) {
            AllLocalDataView()
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
        Task { @MainActor in
        self.showCorruptedCacheAlert = false
            let result = CacheLoadingUtils.loadFriendsFromCache()
            self.friendsInCache = result.friends
            self.statusMessage = result.statusMessage
            self.showCorruptedCacheAlert = result.showCorruptedAlert
        }
    }
    
    private func loadSettings() {
        UserDefaultsSettingsManager.loadSettings(
            sortType: &sortType,
            filterUserStatus: &filterUserStatus,
            filterFavoriteGroups: &filterFavoriteGroups,
            excludeWebUsers: &excludeWebUsers
        )
    }
    
    private func saveSettings() {
        UserDefaultsSettingsManager.saveSettings(
            sortType: sortType,
            filterUserStatus: filterUserStatus,
            filterFavoriteGroups: filterFavoriteGroups,
            excludeWebUsers: excludeWebUsers
        )
    }
}

struct AllLocalDataView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var jsonString: String = "Loading..."
    @State private var isLoading = true
    @State private var error: Error?
    @State private var useAPIData = false

    var body: some View {
        NavigationStack {
            VStack {
                DataSourcePicker(useAPIData: $useAPIData, isLocalDataView: true)
                
                JsonContentView(
                    jsonString: jsonString,
                    isLoading: isLoading,
                    error: error,
                    useAPIData: useAPIData,
                    isLocalDataView: true
                )
            }
            .navigationTitle("Local Friend Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadAllLocalData()
            }
            .onChange(of: useAPIData) { _, _ in
                loadAllLocalData()
            }
            .refreshable {
                await loadAllLocalDataAsync()
            }
        }
    }
    
    private func loadAllLocalData() {
        Task {
            await loadAllLocalDataAsync()
        }
    }
    
    private func loadAllLocalDataAsync() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        let data: String
        if useAPIData {
            data = await FriendCacheManager.getHistoryDataAsJSON()
        } else {
            data = await FriendCacheManager.getCacheDataAsJSON()
        }
        
        await MainActor.run {
            jsonString = data
            isLoading = false
        }
    }
}

#Preview {
    NavigationView {
        RawHistoryDataView()
    }
}
