//
//  FriendsHistoryView.swift
//  Orbit
//
//  Created by NoriDev on 7/5/25.
//

import SwiftUI
import VRCKit
import NukeUI

struct FriendsHistoryView: View {
    @Environment(FriendViewModel.self) private var friendVM
    @Environment(FavoriteViewModel.self) private var favoriteVM
    @State private var allHistories: [FriendHistoryViewModel.MergedHistory]? = nil
    @State private var searchText = ""
    @State private var isPresentedSheet = false
    @State private var sortType: SortType = .timeDescending
    @State private var eventFilters: Set<EventType> = []
    @State private var filterFavoriteGroups: Set<FavoriteGroup.ID> = []

    private let historyVM = FriendHistoryViewModel.shared

    private var filteredAndSortedHistories: [FriendHistoryViewModel.MergedHistory] {
        guard let histories = allHistories else { return [] }

        return histories
            .filter { history in
                searchText.isEmpty || history.displayName.localizedCaseInsensitiveContains(searchText)
            }
            .filter { history in
                eventFilters.isEmpty || eventFilters.contains(history.history.event.eventType)
            }
            .filter { history in
                filterFavoriteGroups.isEmpty ||
                (history.friend != nil && isFriendInFavoriteGroups(friend: history.friend!))
            }
            .sorted {
                switch sortType {
                case .name:
                    $0.displayName.lowercased() < $1.displayName.lowercased()
                case .timeDescending: $0.history.date > $1.history.date
                case .timeAscending: $0.history.date < $1.history.date
                default: $0.history.date > $1.history.date
                }
            }
    }

    private var areFiltersActive: Bool {
        !searchText.isEmpty || !eventFilters.isEmpty || !filterFavoriteGroups.isEmpty
    }

    var body: some View {
        NavigationStack {
            let content = List {
                Section {
                    if allHistories == nil {
                        ForEach(0..<15) { _ in
                            HistoryRowView(mergedHistory: nil)
                        }
                        .redacted(reason: .placeholder)
                    } else {
                        ForEach(filteredAndSortedHistories) { mergedHistory in
                            NavigationLink(destination: UserDetailPresentationView(id: mergedHistory.userId)) {
                                HistoryRowView(mergedHistory: mergedHistory)
                            }
                        }
                    }
                }
                .listSectionSeparator(.hidden, edges: .top)
            }
            .listStyle(.plain)
            .navigationTitle("Friends History")
            .toolbar { navigationToolbar }
            .overlay {
                if allHistories != nil, filteredAndSortedHistories.isEmpty {
                    if areFiltersActive {
                        ContentUnavailableView.search
                    } else {
                        ContentUnavailableView {
                            Label("No history", systemImage: "clock.arrow.circlepath")
                        } description: {
                            Text("If your friend changes their nickname, changed their trust rank, or adds or removes a friend, you'll see a record of here.")
                        }
                    }
                }
            }
            
            if allHistories != nil {
                content
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "이름으로 검색")
            } else {
                content
            }
        }
        .sheet(isPresented: $isPresentedSheet, onDismiss: saveSettings) {
            FilterSheetView(
                sortType: $sortType,
                statusFilter: .constant([]),
                favoriteGroupFilter: $filterFavoriteGroups,
                eventFilter: $eventFilters,
                sortContext: .history,
                visibleSections: [.eventType, .favoriteGroup]
            )
            .presentationDetents([.medium])
        }
        .onAppear(perform: loadSettings)
        .task { await loadInitialData() }
        .refreshable { await loadAndRefreshData() }
        .alert("캐시가 손상됨", isPresented: Binding(
            get: { friendVM.isCacheCorrupted },
            set: { friendVM.isCacheCorrupted = $0 }
        )) {
            Button("삭제", role: .destructive) {
                FriendCacheManager.deleteCache()
                friendVM.isCacheCorrupted = false
                Task { await loadAndRefreshData() }
            }
            Button("취소", role: .cancel) {
                friendVM.isCacheCorrupted = false
            }
        } message: {
            Text("친구 목록 캐시 파일이 손상되어 기록을 제대로 표시할 수 없습니다. 파일을 삭제하시겠습니까?")
        }
    }

    @ToolbarContentBuilder
    private var navigationToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("", systemImage: IconSet.dots.systemName) {
                isPresentedSheet.toggle()
            }
            .disabled(allHistories == nil)
        }
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard
        if let rawSortType = defaults.string(forKey: "history_sort_type"),
           let restoredSortType = SortType(rawValue: rawSortType) {
            self.sortType = restoredSortType
        }

        if let rawEvents = defaults.array(forKey: "history_filter_event_types") as? [String] {
            self.eventFilters = Set(rawEvents.compactMap(EventType.init))
        }

        if let rawGroups = defaults.array(forKey: "history_filter_favorite_groups") as? [String] {
            self.filterFavoriteGroups = Set(rawGroups)
        }
    }

    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(self.sortType.rawValue, forKey: "history_sort_type")

        let eventRawValues = self.eventFilters.map { $0.rawValue }
        defaults.set(eventRawValues, forKey: "history_filter_event_types")

        let groupIDs = Array(self.filterFavoriteGroups)
        defaults.set(groupIDs, forKey: "history_filter_favorite_groups")
    }

    private func eventFilterBinding(for eventType: EventType) -> Binding<Bool> {
        Binding<Bool>(
            get: { self.eventFilters.contains(eventType) },
            set: {
                if $0 { self.eventFilters.insert(eventType) } else { self.eventFilters.remove(eventType) }
            }
        )
    }

    private func favoriteGroupFilterBinding(for groupId: FavoriteGroup.ID) -> Binding<Bool> {
        Binding<Bool>(
            get: { self.filterFavoriteGroups.contains(groupId) },
            set: {
                if $0 { self.filterFavoriteGroups.insert(groupId) } else { self.filterFavoriteGroups.remove(groupId) }
            }
        )
    }

    private func isFriendInFavoriteGroups(friend: Friend) -> Bool {
        return filterFavoriteGroups.contains { groupId in
            favoriteVM.getFavoriteFriends(groupId)?.contains(where: { $0.id == friend.id }) ?? false
        }
    }

    @MainActor
    private func loadInitialData() async {
        if self.allHistories == nil {
            if friendVM.allFriends.isEmpty { await friendVM.fetchAllFriends { _ in } }
            self.allHistories = await historyVM.loadAllHistories(friends: friendVM.allFriends, userService: friendVM.appVM?.services.userService)
        }
    }

    @MainActor
    private func loadAndRefreshData() async {
        await friendVM.fetchAllFriends { _ in }
        self.allHistories = await historyVM.loadAllHistories(friends: friendVM.allFriends, userService: friendVM.appVM?.services.userService)
    }
}

struct HistoryRowView: View {
    let mergedHistory: FriendHistoryViewModel.MergedHistory?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            LazyImage(url: mergedHistory?.avatarThumbnailUrl) { state in
                if let image = state.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mergedHistory?.displayName ?? "Placeholder 이름")
                    .font(.headline)
                
                Text(mergedHistory?.history.event.description ?? "이벤트 유형이 여기에 표시됩니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                Text(mergedHistory?.relativeDateString ?? "시간 정보")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PreviewContainer {
        FriendsHistoryView()
    }
}
