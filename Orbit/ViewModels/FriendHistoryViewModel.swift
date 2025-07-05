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
    private let userDefaults = UserDefaults.standard
    private let allHistoryKey = "allFriendHistoryKeys" // 모든 기록 키를 저장할 키

    // ✅ 친구 정보와 기록을 함께 담을 구조체 추가
    struct MergedHistory: Identifiable, Hashable {
        let id: UUID
        let friend: Friend?
        let history: FriendHistory
    }
    
    private init() {}

    // ✅ 모든 친구 기록을 불러오는 함수 추가
    func loadAllHistories(friends: [Friend]) -> [MergedHistory] {
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
        
        // 시간순으로 정렬
        allHistories.sort { $0.date > $1.date }
        
        // 친구 정보와 병합
        let friendsDict = Dictionary(uniqueKeysWithValues: friends.map { ($0.id, $0) })
        let mergedHistories = allHistories.map { history in
            MergedHistory(id: history.id, friend: friendsDict[history.friendId], history: history)
        }
        
        return mergedHistories
    }
    
    // 특정 친구의 모든 기록을 불러오기
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

    // 새로운 기록 저장하기
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
            
            // ✅ 전체 기록 키 목록에 현재 키 추가
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
