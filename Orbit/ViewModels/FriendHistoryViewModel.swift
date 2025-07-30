//
//  FriendHistoryViewModel.swift
//  Orbit
//
//  Created by NoriDev on 7/5/25.
//

import Foundation
import VRCKit

@MainActor
class FriendHistoryViewModel: ObservableObject {
    static let shared = FriendHistoryViewModel()

    struct MergedHistory: Identifiable, Hashable {
        let id: UUID
        let friend: Friend?
        let deletedUser: UserDetail?
        let history: FriendHistory
        let relativeDateString: String
        
        var displayName: String {
            friend?.displayName ?? deletedUser?.displayName ?? "알 수 없는 사용자"
        }
        
        var avatarThumbnailUrl: URL? {
            friend?.avatarThumbnailUrl ?? deletedUser?.avatarThumbnailUrl
        }
        
        var userId: String {
            friend?.id ?? deletedUser?.id ?? history.friendId
        }
    }
    
    private let accountManager = AccountManager.shared
    
    private var friendsDict: [String: Friend] = [:]

    private init() {}

    @MainActor
    func loadAllHistories(friends: [Friend], userService: UserProvidable?) async -> [MergedHistory] {
        self.friendsDict = Dictionary(uniqueKeysWithValues: friends.map { ($0.id, $0) })
        
        let allHistoryData = FriendCacheManager.loadAllFriendHistory()
        var allHistories: [FriendHistory] = []
        
        for (_, histories) in allHistoryData {
            allHistories.append(contentsOf: histories)
        }
        
        allHistories.sort { $0.date > $1.date }
        
        var mergedHistories: [MergedHistory] = []
        for history in allHistories {
            let relativeDate = await DateUtil.shared.formatRelative(from: history.date)
            let friend = friendsDict[history.friendId]
            var deletedUser: UserDetail?

            if friend == nil, let userService = userService {
                do {
                    deletedUser = try await userService.fetchUser(userId: history.friendId)
                } catch {
                    print("Could not fetch user data for deleted friend \(history.friendId): \(error)")
                }
            }
            
            mergedHistories.append(
                MergedHistory(
                    id: history.id,
                    friend: friend,
                    deletedUser: deletedUser,
                    history: history,
                    relativeDateString: relativeDate
                )
            )
        }
        
        return mergedHistories
    }
    
    func getFriend(byId id: String) -> Friend? {
        return friendsDict[id]
    }
    
    func loadHistory(for friendId: String) -> [FriendHistory] {
        let allHistory = FriendCacheManager.loadAllFriendHistory()
        return allHistory[friendId] ?? []
    }

    func saveHistory(event: HistoryEvent, for friendId: String) {
        print("💾 [saveHistory] Attempting to save history for friend: \(friendId), event: \(event)")
        
        guard let accountDirectory = accountManager.getCurrentAccountDirectory() else { 
            print("❌ [saveHistory] Cannot get account directory - accountManager.getCurrentAccountDirectory() returned nil")
            return 
        }
        
        print("💾 [saveHistory] Account directory: \(accountDirectory.path)")
        
        var histories = loadHistory(for: friendId)
        print("💾 [saveHistory] Loaded \(histories.count) existing histories for friend: \(friendId)")
        
        let newHistory = FriendHistory(friendId: friendId, event: event)
        print("💾 [saveHistory] Created new history entry with ID: \(newHistory.id)")
        
        if let lastHistory = histories.first, lastHistory.event == newHistory.event {
            print("⚠️ [saveHistory] Skipping duplicate event for friend: \(friendId)")
            return
        }
        
        histories.insert(newHistory, at: 0)
        print("💾 [saveHistory] Added new history, total count now: \(histories.count)")
        
        var allHistory = FriendCacheManager.loadAllFriendHistory()
        allHistory[friendId] = histories
        
        let historyFileURL = accountDirectory.appendingPathComponent("friendHistory.json")
        print("💾 [saveHistory] Saving to file: \(historyFileURL.path)")
        
        do {
            if !FileManager.default.fileExists(atPath: accountDirectory.path) {
                try FileManager.default.createDirectory(at: accountDirectory, withIntermediateDirectories: true, attributes: nil)
                print("📁 [saveHistory] Created directory: \(accountDirectory.path)")
            }
            
            let data = try JSONEncoder().encode(allHistory)
            print("💾 [saveHistory] Encoded \(data.count) bytes")
            try data.write(to: historyFileURL)
            print("✅ [saveHistory] Successfully saved history for friend: \(friendId)")
        } catch {
            print("❌ [saveHistory] Error saving history for \(friendId): \(error)")
        }
    }

    func clearAllHistory() {
        guard let accountDirectory = accountManager.getCurrentAccountDirectory() else { return }
        
        let historyFileURL = accountDirectory.appendingPathComponent("friendHistory.json")
        
        if FileManager.default.fileExists(atPath: historyFileURL.path) {
            do {
                try FileManager.default.removeItem(at: historyFileURL)
                print("All history cleared successfully")
            } catch {
                print("Error clearing history: \(error)")
            }
        }
    }
}
