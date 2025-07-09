//
//  FriendCacheManager.swift
//  Orbit
//
//  Created by NoriDev on 7/6/25.
//

import Foundation
import VRCKit

class FriendCacheManager {
    private static let fileName = "friendCache.json"
    
    struct CompleteBackupData: Codable {
        let friends: [Friend]
        let friendHistory: [String: [FriendHistory]]
        let exportDate: Date
        let version: String
    }
    
    struct CompleteBackupResult {
        let friendMergeResult: MergeResult
        let historyImported: Int
        let isCompleteBackup: Bool
    }
    
    struct MergeResult {
        let mergedFriends: [Friend]
        let addedCount: Int
        let updatedCount: Int
        let unchangedCount: Int
    }
    
    struct PreviewResult {
        let addedCount: Int
        let updatedCount: Int
        let backupFriendsCount: Int
        let currentFriendsCount: Int
        let historyAddedCount: Int
        let historyFriendsCount: Int
        
        var totalChanges: Int {
            return addedCount + updatedCount + historyAddedCount
        }
    }

    private static var cacheURL: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory.appendingPathComponent(fileName)
    }

    static func saveFriends(_ friends: [Friend]) {
        guard let url = cacheURL else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .formatted(.iso8601Full)
            print("--- Saving Cache ---")
            let data = try encoder.encode(friends)
            print("Attempting to save \(data.count) bytes to friendCache.json")
            try data.write(to: url, options: .atomic)
            print("Save successful.")
            print("--------------------")
        } catch {
            print("Error saving friend cache to file: \(error)")
        }
    }

    static func loadFriends() throws -> [Friend] {
        guard let url = cacheURL, FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        
        guard let rawString = String(data: data, encoding: .utf8) else {
            print("Could not convert data to UTF-8 string.")
            return try JSONDecoder().decode([Friend].self, from: data)
        }
        
        let sanitizedString = rawString.filter { character in
            guard let firstScalar = character.unicodeScalars.first else { return false }
            let controlRanges = [0x00...0x1F, 0x7F...0x9F]
            return !controlRanges.contains(where: { $0.contains(Int(firstScalar.value)) })
        }

        if let sanitizedData = sanitizedString.data(using: .utf8) {
            return try JSONDecoder().decode([Friend].self, from: sanitizedData)
        }
        
        return try JSONDecoder().decode([Friend].self, from: data)
    }
    
    static func deleteCache() {
        guard let url = cacheURL, FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.removeItem(at: url)
            print("Cache file deleted successfully.")
        } catch {
            print("Error deleting cache file: \(error)")
        }
    }
    
    static func loadRawData() -> String? {
        guard let url = cacheURL, let data = try? Data(contentsOf: url) else {
            return nil
        }

        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }

        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Backup & Restore Functions
    
    private static func loadAllFriendHistory() -> [String: [FriendHistory]] {
        let userDefaults = UserDefaults.standard
        let allHistoryKey = "allFriendHistoryKeys"
        let allKeys = userDefaults.stringArray(forKey: allHistoryKey) ?? []
        
        var allHistory: [String: [FriendHistory]] = [:]
        
        for key in allKeys {
            if let data = userDefaults.data(forKey: key) {
                do {
                    let histories = try JSONDecoder().decode([FriendHistory].self, from: data)
                    let friendId = String(key.dropFirst(8)) // "history_".count = 8
                    allHistory[friendId] = histories
                } catch {
                    print("Error decoding history for key \(key): \(error)")
                }
            }
        }
        
        return allHistory
    }
    
    private static func loadCompleteBackup(url: URL) throws -> CompleteBackupData {
        print("--- Loading Complete Backup ---")
        print("Backup file URL: \(url)")
        
        let fileExists = url.startAccessingSecurityScopedResource()
        defer {
            if fileExists {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            print("File does not exist at path: \(url.path)")
            // URL이 File Provider 경로인 경우 다른 방법으로 시도
            do {
                let _ = try Data(contentsOf: url)
                print("File exists but path check failed - proceeding with URL access")
            } catch {
                print("File access failed: \(error)")
                throw NSError(domain: "FileNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "백업 파일을 찾을 수 없습니다."])
            }
        }
        
        print("File exists: true")
        
        let data = try Data(contentsOf: url)
        print("Loaded \(data.count) bytes from backup file")
        
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("JSON keys: \(Array(jsonObject.keys))")
            
            if let friends = jsonObject["friends"] as? [[String: Any]] {
                print("Friends count in JSON: \(friends.count)")
            }
            if let history = jsonObject["friendHistory"] as? [String: Any] {
                print("Friend history entries: \(history.keys.count)")
            }
            if let exportDate = jsonObject["exportDate"] {
                print("Export date: \(exportDate)")
            }
            if let version = jsonObject["version"] {
                print("Version: \(version)")
            }
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(.iso8601Full)
            let completeBackup = try decoder.decode(CompleteBackupData.self, from: data)
            print("✅ Successfully loaded complete backup: \(completeBackup.friends.count) friends, \(completeBackup.friendHistory.count) history entries")
            print("Export date: \(completeBackup.exportDate)")
            print("Version: \(completeBackup.version)")
            print("---------------------------")
            return completeBackup
        } catch {
            print("❌ Complete backup decoding failed: \(error)")
            throw NSError(domain: "BackupLoadError", code: 400, userInfo: [NSLocalizedDescriptionKey: "백업 파일 형식이 올바르지 않습니다: \(error.localizedDescription)"])
        }
    }
    
    static func generatePreview(from backupURL: URL) throws -> PreviewResult {
        let completeBackup = try loadCompleteBackup(url: backupURL)
        let currentFriends = try loadFriends()
        let currentHistory = loadAllFriendHistory()
        
        print("--- Preview Generation ---")
        print("Backup friends: \(completeBackup.friends.count)")
        print("Current friends: \(currentFriends.count)")
        print("Backup history entries: \(completeBackup.friendHistory.count)")
        print("Current history entries: \(currentHistory.count)")
        
        let currentFriendsDict = Dictionary(uniqueKeysWithValues: currentFriends.map { ($0.id, $0) })
        
        var addedCount = 0
        var updatedCount = 0
        var historyAddedCount = 0
        var historyFriendsCount = 0
        
        // 친구 목록 변경사항 확인
        for (index, backupFriend) in completeBackup.friends.enumerated() {
            if index < 5 {
                print("Checking backup friend \(index + 1): \(backupFriend.displayName) (ID: \(backupFriend.id))")
            }
            
            if let currentFriend = currentFriendsDict[backupFriend.id] {
                let shouldUpdate = shouldUpdateFriend(current: currentFriend, backup: backupFriend)
                if index < 5 {
                    print("  Found existing, should update: \(shouldUpdate)")
                }
                if shouldUpdate {
                    updatedCount += 1
                }
            } else {
                if index < 5 {
                    print("  New friend")
                }
                addedCount += 1
            }
        }
        
        // 친구 기록 변경사항 확인
        for (friendId, backupHistories) in completeBackup.friendHistory {
            let currentHistories = currentHistory[friendId] ?? []
            let currentHistoryIds = Set(currentHistories.map { $0.id })
            
            var newHistoriesCount = 0
            for backupHistory in backupHistories {
                if !currentHistoryIds.contains(backupHistory.id) {
                    newHistoriesCount += 1
                }
            }
            
            if newHistoriesCount > 0 {
                historyAddedCount += newHistoriesCount
                historyFriendsCount += 1
                print("Friend \(friendId): \(newHistoriesCount) new history entries")
            }
        }
        
        print("Preview result: Added \(addedCount), Updated \(updatedCount), History Added \(historyAddedCount), History Friends \(historyFriendsCount)")
        print("-------------------------")
        
        return PreviewResult(
            addedCount: addedCount,
            updatedCount: updatedCount,
            backupFriendsCount: completeBackup.friends.count,
            currentFriendsCount: currentFriends.count,
            historyAddedCount: historyAddedCount,
            historyFriendsCount: historyFriendsCount
        )
    }
    
    static func importCompleteBackup(from backupURL: URL) throws -> CompleteBackupResult {
        let completeBackup = try loadCompleteBackup(url: backupURL)
        let currentFriends = try loadFriends()
        
        // 친구 목록 병합
        let friendMergeResult = mergeFriends(current: currentFriends, backup: completeBackup.friends)
        saveFriends(friendMergeResult.mergedFriends)
        
        // 친구 기록 병합
        let historyImported = importFriendHistory(completeBackup.friendHistory)
        
        return CompleteBackupResult(
            friendMergeResult: friendMergeResult,
            historyImported: historyImported,
            isCompleteBackup: true
        )
    }
    
    private static func importFriendHistory(_ historyData: [String: [FriendHistory]]) -> Int {
        let userDefaults = UserDefaults.standard
        let allHistoryKey = "allFriendHistoryKeys"
        var allKeys = userDefaults.stringArray(forKey: allHistoryKey) ?? []
        var importedCount = 0
        
        for (friendId, histories) in historyData {
            let key = "history_\(friendId)"
            
            var existingHistories = [FriendHistory]()
            if let existingData = userDefaults.data(forKey: key) {
                existingHistories = (try? JSONDecoder().decode([FriendHistory].self, from: existingData)) ?? []
            }
            
            // 병합 (중복 제거)
            var mergedHistories = existingHistories
            let existingIds = Set(existingHistories.map { $0.id })
            
            for history in histories {
                if !existingIds.contains(history.id) {
                    mergedHistories.append(history)
                    importedCount += 1
                }
            }
            
            mergedHistories.sort { $0.date > $1.date }
            
            do {
                let data = try JSONEncoder().encode(mergedHistories)
                userDefaults.set(data, forKey: key)
                
                if !allKeys.contains(key) {
                    allKeys.append(key)
                }
            } catch {
                print("Error encoding history for \(friendId): \(error)")
            }
        }
        
        userDefaults.set(allKeys, forKey: allHistoryKey)
        print("Imported \(importedCount) friend history entries")
        return importedCount
    }
    
    private static func mergeFriends(current: [Friend], backup: [Friend]) -> MergeResult {
        print("--- Merging Friends ---")
        print("Current friends count: \(current.count)")
        print("Backup friends count: \(backup.count)")
        
        var mergedFriends: [Friend] = []
        var addedCount = 0
        var updatedCount = 0
        var unchangedCount = 0
        
        var currentFriendsDict = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        print("Current friends dictionary created with \(currentFriendsDict.count) entries")
        
        for (index, backupFriend) in backup.enumerated() {
            if index < 5 {
                print("Processing backup friend \(index + 1): \(backupFriend.displayName) (ID: \(backupFriend.id))")
            }
            
            if let currentFriend = currentFriendsDict[backupFriend.id] {
                let shouldUpdate = shouldUpdateFriend(current: currentFriend, backup: backupFriend)
                if index < 5 {
                    print("  Found existing friend, should update: \(shouldUpdate)")
                    if shouldUpdate {
                        print("    Current lastLogin: \(currentFriend.lastLogin?.description ?? "nil")")
                        print("    Backup lastLogin: \(backupFriend.lastLogin?.description ?? "nil")")
                        print("    Current displayName: \(currentFriend.displayName)")
                        print("    Backup displayName: \(backupFriend.displayName)")
                        print("    Current status: \(currentFriend.status)")
                        print("    Backup status: \(backupFriend.status)")
                    }
                }
                
                if shouldUpdate {
                    mergedFriends.append(backupFriend)
                    updatedCount += 1
                } else {
                    mergedFriends.append(currentFriend)
                    unchangedCount += 1
                }
                currentFriendsDict.removeValue(forKey: backupFriend.id)
            } else {
                if index < 5 {
                    print("  New friend found")
                }
                mergedFriends.append(backupFriend)
                addedCount += 1
            }
        }
        
        for (_, currentFriend) in currentFriendsDict {
            mergedFriends.append(currentFriend)
            unchangedCount += 1
        }
        
        print("Merge completed:")
        print("  Added: \(addedCount)")
        print("  Updated: \(updatedCount)")
        print("  Unchanged: \(unchangedCount)")
        print("  Total: \(mergedFriends.count)")
        print("  Remaining current friends: \(currentFriendsDict.count)")
        print("----------------------")
        
        return MergeResult(
            mergedFriends: mergedFriends,
            addedCount: addedCount,
            updatedCount: updatedCount,
            unchangedCount: unchangedCount
        )
    }
    
    private static func shouldUpdateFriend(current: Friend, backup: Friend) -> Bool {
        if let currentLastLogin = current.lastLogin,
           let backupLastLogin = backup.lastLogin {
            return backupLastLogin > currentLastLogin
        }
        
        if current.lastLogin == nil && backup.lastLogin != nil {
            return true
        }
        
        if current.displayName != backup.displayName {
            return true
        }
        
        if current.status != backup.status {
            return true
        }
        
        return false
    }
    
    static func exportCompleteBackup() -> URL? {
        guard let cacheURL = cacheURL,
              FileManager.default.fileExists(atPath: cacheURL.path) else {
            return nil
        }
        
        do {
            let friendsData = try Data(contentsOf: cacheURL)
            let friends = try JSONDecoder().decode([Friend].self, from: friendsData)
            
            let friendHistory = loadAllFriendHistory()
            
            let completeBackup = CompleteBackupData(
                friends: friends,
                friendHistory: friendHistory,
                exportDate: Date(),
                version: "1.0"
            )
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .formatted(.iso8601Full)
            let backupData = try encoder.encode(completeBackup)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
            let filename = "Orbit_Friends_Data_Backup_\(timestamp).json"
            
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
            }
            let exportURL = documentsDirectory.appendingPathComponent(filename)
            
            try backupData.write(to: exportURL)
            print("Complete backup exported: \(friends.count) friends, \(friendHistory.count) history entries")
            return exportURL
            
        } catch {
            print("Error exporting complete backup: \(error)")
            return nil
        }
    }

    // MARK: - Data Status Information
    
    struct DataStatus {
        let friendsCount: Int
        let friendsDataSize: Int64
        let historyCount: Int
        let historyDataSize: Int64
        let totalDataSize: Int64
        let lastModified: Date?
        
        var totalEntries: Int {
            return friendsCount + historyCount
        }
        
        var formattedTotalSize: String {
            return ByteCountFormatter().string(fromByteCount: totalDataSize)
        }
        
        var formattedFriendsSize: String {
            return ByteCountFormatter().string(fromByteCount: friendsDataSize)
        }
        
        var formattedHistorySize: String {
            return ByteCountFormatter().string(fromByteCount: historyDataSize)
        }
    }
    
    static func getDataStatus() -> DataStatus {
        let friends = (try? loadFriends()) ?? []
        let friendHistory = loadAllFriendHistory()
        
        // 친구 데이터 크기 계산
        var friendsDataSize: Int64 = 0
        if let friendsData = try? JSONEncoder().encode(friends) {
            friendsDataSize = Int64(friendsData.count)
        }
        
        // 친구 기록 데이터 크기 계산
        var historyDataSize: Int64 = 0
        if let historyData = try? JSONEncoder().encode(friendHistory) {
            historyDataSize = Int64(historyData.count)
        }
        
        // 총 기록 수 계산
        let totalHistoryCount = friendHistory.values.reduce(0) { $0 + $1.count }
        
        // 친구 캐시 파일의 마지막 수정 날짜
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cacheURL = documentsPath.appendingPathComponent(fileName)
        
        var lastModified: Date?
        if let attributes = try? FileManager.default.attributesOfItem(atPath: cacheURL.path),
           let modificationDate = attributes[.modificationDate] as? Date {
            lastModified = modificationDate
        }
        
        return DataStatus(
            friendsCount: friends.count,
            friendsDataSize: friendsDataSize,
            historyCount: totalHistoryCount,
            historyDataSize: historyDataSize,
            totalDataSize: friendsDataSize + historyDataSize,
            lastModified: lastModified
        )
    }
}
