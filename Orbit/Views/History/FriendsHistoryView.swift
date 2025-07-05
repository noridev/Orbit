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

        let searched = histories.filter {
            searchText.isEmpty || $0.friend?.displayName.localizedCaseInsensitiveContains(searchText) ?? false
        }

        let eventFiltered = searched.filter {
            eventFilters.isEmpty || eventFilters.contains($0.history.event.eventType)
        }

        let favoriteGroupFiltered = eventFiltered.filter { history in
            filterFavoriteGroups.isEmpty ||
            (history.friend != nil && isFriendInFavoriteGroups(friend: history.friend!))
        }

        return favoriteGroupFiltered.sorted {
            switch sortType {
            case .name:
                return $0.friend?.displayName.lowercased() ?? "" < $1.friend?.displayName.lowercased() ?? ""
            case .timeDescending:
                return $0.history.date > $1.history.date
            case .timeAscending:
                return $0.history.date < $1.history.date
            }
        }
    }

    private var areFiltersActive: Bool {
        !searchText.isEmpty || !eventFilters.isEmpty || !filterFavoriteGroups.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                if allHistories == nil {
                    ForEach(0..<15) { _ in
                        HistoryRowView(mergedHistory: nil)
                    }
                    .redacted(reason: .placeholder)
                } else if filteredAndSortedHistories.isEmpty {
                    // for .overlay
                } else {
                    ForEach(filteredAndSortedHistories) { mergedHistory in
                        if let friend = mergedHistory.friend {
                            NavigationLink(destination: UserDetailPresentationView(id: friend.id)) {
                                HistoryRowView(mergedHistory: mergedHistory)
                            }
                        } else {
                            HistoryRowView(mergedHistory: mergedHistory)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Friends History")
            .toolbar { navigationToolbar }
            .searchable(text: $searchText, prompt: "이름으로 검색")
            .overlay {
                if let histories = allHistories, filteredAndSortedHistories.isEmpty {
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
            .sheet(isPresented: $isPresentedSheet, onDismiss: saveSettings) {
                historyFilterSheet
                    .presentationDetents([.medium])
            }
        }
        .onAppear(perform: loadSettings)
        .task { await loadInitialData() }
        .refreshable { await loadAndRefreshData() }
    }

    @ToolbarContentBuilder
    private var navigationToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { isPresentedSheet = true }) {
                Image(systemName: IconSet.dots.systemName)
            }
            .disabled(allHistories == nil)
        }
    }

    private var historyFilterSheet: some View {
        NavigationStack {
            Form {
                Picker("Sort", selection: $sortType) {
                    ForEach(SortType.allCases) { type in
                        Label(type.description, systemImage: type.icon.systemName).tag(type)
                    }
                }
                .pickerStyle(.inline)

                Section {
                    ForEach(EventType.allCases, id: \.self) { eventType in
                        Toggle(isOn: eventFilterBinding(for: eventType)) {
                            Label(eventType.description, systemImage: eventType.icon.systemName)
                        }
                    }
                } header: {
                    HStack {
                        Text("이벤트 종류")
                        Spacer()
                        Button("Clear") { eventFilters.removeAll() }.font(.caption)
                    }
                }

                Section {
                    ForEach(favoriteVM.favoriteGroups(.friend)) { group in
                        Toggle(isOn: favoriteGroupFilterBinding(for: group.id)) {
                            Label(group.displayName, systemImage: IconSet.favoriteGroup.systemName)
                        }
                    }
                } header: {
                    HStack {
                        Text("Favorite Groups")
                        Spacer()
                        Button("Clear") { filterFavoriteGroups.removeAll() }.font(.caption)
                    }
                }
            }
            .navigationTitle("Display Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button(action: { isPresentedSheet = false }) {
                        ExitButton()
                    }
                }
            }
        }
    }

    enum SortType: String, CaseIterable, CustomStringConvertible, Identifiable {
        case name = "이름"
        case timeDescending = "최신순"
        case timeAscending = "오래된순"

        var description: String { self.rawValue }
        var id: String { self.rawValue }

        var icon: Iconizable {
            switch self {
            case .name: return IconSet.at
            case .timeDescending, .timeAscending: return IconSet.calendar
            }
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
            self.allHistories = await historyVM.loadAllHistories(friends: friendVM.allFriends)
        }
    }

    @MainActor
    private func loadAndRefreshData() async {
        self.allHistories = nil
        await friendVM.fetchAllFriends { _ in }
        self.allHistories = await historyVM.loadAllHistories(friends: friendVM.allFriends)
    }
}

struct HistoryRowView: View {
    let mergedHistory: FriendHistoryViewModel.MergedHistory?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            LazyImage(url: mergedHistory?.friend?.avatarThumbnailUrl) { state in
                if let image = state.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mergedHistory?.friend?.displayName ?? "플레이스홀더 이름")
                    .font(.headline)
                
                Text(mergedHistory?.history.event.description ?? "이벤트 설명이 여기에 표시됩니다.")
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
