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
        let history: FriendHistory
        let relativeDateString: String
    }
    
    let userDefaults = UserDefaults.standard
    let allHistoryKey = "allFriendHistoryKeys"
    
    private var friendsDict: [String: Friend] = [:]

    private init() {}

    func loadAllHistories(friends: [Friend]) async -> [MergedHistory] {
        self.friendsDict = Dictionary(uniqueKeysWithValues: friends.map { ($0.id, $0) })
        
        let allKeys = userDefaults.stringArray(forKey: allHistoryKey) ?? []
        var allHistories: [FriendHistory] = []
        
        for key in allKeys {
            if let data = userDefaults.data(forKey: key) {
                do {
                    let histories = try JSONDecoder().decode([FriendHistory].self, from: data)
                    allHistories.append(contentsOf: histories)
                } catch {
                    print("Error decoding history for key \(key): \(error)")
                }
            }
        }
        
        allHistories.sort { $0.date > $1.date }
        
        var mergedHistories: [MergedHistory] = []
        for history in allHistories {
            let relativeDate = await DateUtil.shared.formatRelative(from: history.date)
            mergedHistories.append(
                MergedHistory(
                    id: history.id,
                    friend: friendsDict[history.friendId],
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
        let key = "history_\(friendId)"
        guard let data = userDefaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([FriendHistory].self, from: data)
        } catch {
            print("Error decoding history for \(friendId): \(error)")
            return []
        }
    }

    func saveHistory(event: HistoryEvent, for friendId: String) {
        let key = "history_\(friendId)"
        var histories = loadHistory(for: friendId)
        let newHistory = FriendHistory(friendId: friendId, event: event)
        
        if let lastHistory = histories.first, lastHistory.event == newHistory.event {
            return
        }
        
        histories.insert(newHistory, at: 0)

        do {
            let data = try JSONEncoder().encode(histories)
            userDefaults.set(data, forKey: key)
            
            var allKeys = userDefaults.stringArray(forKey: allHistoryKey) ?? []
            if !allKeys.contains(key) {
                allKeys.append(key)
                userDefaults.set(allKeys, forKey: allHistoryKey)
            }
            
        } catch {
            print("Error encoding history for \(friendId): \(error)")
        }
    }
}
