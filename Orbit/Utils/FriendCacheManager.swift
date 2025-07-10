//
//  FriendCacheManager.swift
//  Orbit
//
//  Created by NoriDev on 7/6/25.
//

import Foundation
import VRCKit
import Compression

extension Data {
    func compressed(using algorithm: Algorithm) throws -> Data {
        return try self.withUnsafeBytes { bytes in
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
            defer { buffer.deallocate() }
            
            let compressedSize = compression_encode_buffer(
                buffer, count,
                bytes.bindMemory(to: UInt8.self).baseAddress!, count,
                nil, algorithm.rawValue
            )
            
            guard compressedSize > 0 else {
                throw NSError(domain: "CompressionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Compression failed"])
            }
            
            return Data(bytes: buffer, count: compressedSize)
        }
    }
    
    func decompressed(using algorithm: Algorithm) throws -> Data {
        return try self.withUnsafeBytes { bytes in
            let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count * 4)
            defer { destinationBuffer.deallocate() }
            
            let decompressedSize = compression_decode_buffer(
                destinationBuffer, count * 4,
                bytes.bindMemory(to: UInt8.self).baseAddress!, count,
                nil, algorithm.rawValue
            )
            
            guard decompressedSize > 0 else {
                throw NSError(domain: "DecompressionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Decompression failed"])
            }
            
            return Data(bytes: destinationBuffer, count: decompressedSize)
        }
    }
}

class FriendCacheManager {
    private static let fileName = "friendCache.json"
    
    @MainActor
    private static var accountManager: AccountManager {
        return AccountManager.shared
    }
    
    struct CompleteBackupData: Codable {
        let friends: [Friend]
        let friendHistory: [String: [FriendHistory]]
        let exportDate: Date
        let version: String
    }
    
    struct MultiAccountBackupData: Codable {
        let version: String
        let exportDate: Date
        let exportedBy: String
        let totalAccounts: Int
        let accounts: [String: AccountData]
        let metadata: BackupMetadata
    }
    
    struct AccountData: Codable {
        let userId: String
        let userName: String
        let lastUpdated: Date
        let friendsCount: Int
        let historyCount: Int
        let friends: [Friend]
        let friendHistory: [String: [FriendHistory]]
    }
    
    struct BackupMetadata: Codable {
        let totalFriends: Int
        let totalHistoryEntries: Int
        let appVersion: String
        let deviceType: String
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

    @MainActor
    private static var cacheURL: URL? {
        guard let accountDirectory = accountManager.getCurrentAccountDirectory() else { return nil }
        return accountDirectory.appendingPathComponent(fileName)
    }

    @MainActor
    static func saveFriends(_ friends: [Friend]) {
        guard let url = cacheURL else { 
            print("❌ [saveFriends] Cannot get cache URL - accountManager.getCurrentAccountDirectory() returned nil")
            return 
        }
        
        print("📝 [saveFriends] Saving \(friends.count) friends to: \(url.path)")
        
        do {
            let directory = url.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                print("📁 [saveFriends] Created directory: \(directory.path)")
            }
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .formatted(.iso8601Full)
            let data = try encoder.encode(friends)
            print("📝 [saveFriends] Encoded \(data.count) bytes")
            try data.write(to: url, options: .atomic)
            print("✅ [saveFriends] Save successful to: \(url.path)")
        } catch {
            print("❌ [saveFriends] Error saving friend cache: \(error)")
        }
    }

    @MainActor
    static func loadFriends() throws -> [Friend] {
        guard let url = cacheURL else {
            print("❌ [loadFriends] Cannot get cache URL - accountManager.getCurrentAccountDirectory() returned nil")
            return []
        }
        
        print("📖 [loadFriends] Attempting to load from: \(url.path)")
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("⚠️ [loadFriends] File does not exist at: \(url.path)")
            return []
        }

        let data = try Data(contentsOf: url)
        print("📖 [loadFriends] Loaded \(data.count) bytes from file")
        
        guard let rawString = String(data: data, encoding: .utf8) else {
            print("⚠️ [loadFriends] Could not convert data to UTF-8 string")
            return try JSONDecoder().decode([Friend].self, from: data)
        }
        
        let sanitizedString = rawString.filter { character in
            guard let firstScalar = character.unicodeScalars.first else { return false }
            let controlRanges = [0x00...0x1F, 0x7F...0x9F]
            return !controlRanges.contains(where: { $0.contains(Int(firstScalar.value)) })
        }

        if let sanitizedData = sanitizedString.data(using: .utf8) {
            let friends = try JSONDecoder().decode([Friend].self, from: sanitizedData)
            print("✅ [loadFriends] Successfully loaded \(friends.count) friends")
            return friends
        }
        
        let friends = try JSONDecoder().decode([Friend].self, from: data)
        print("✅ [loadFriends] Successfully loaded \(friends.count) friends (fallback)")
        return friends
    }
    
    @MainActor
    static func deleteCache() {
        guard let url = cacheURL, FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.removeItem(at: url)
            print("Cache file deleted successfully.")
        } catch {
            print("Error deleting cache file: \(error)")
        }
    }
    
    @MainActor
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
    
    @MainActor
    static func loadAllFriendHistory() -> [String: [FriendHistory]] {
        guard let accountDirectory = accountManager.getCurrentAccountDirectory() else { 
            print("❌ [loadAllFriendHistory] Cannot get account directory - accountManager.getCurrentAccountDirectory() returned nil")
            return [:]
        }
        
        let historyFileURL = accountDirectory.appendingPathComponent("friendHistory.json")
        print("📖 [loadAllFriendHistory] Attempting to load from: \(historyFileURL.path)")
        
        guard FileManager.default.fileExists(atPath: historyFileURL.path) else { 
            print("⚠️ [loadAllFriendHistory] File does not exist at: \(historyFileURL.path)")
            return [:]
        }
        
        do {
            let data = try Data(contentsOf: historyFileURL)
            print("📖 [loadAllFriendHistory] Loaded \(data.count) bytes from file")
            let allHistory = try JSONDecoder().decode([String: [FriendHistory]].self, from: data)
            let totalEntries = allHistory.values.reduce(0) { $0 + $1.count }
            print("✅ [loadAllFriendHistory] Successfully loaded \(allHistory.count) friend histories with \(totalEntries) total entries")
            return allHistory
        } catch {
            print("❌ [loadAllFriendHistory] Failed to load friend history: \(error)")
            return [:]
        }
    }
    
    private static func loadBackupData(url: URL) throws -> Data {
        print("--- Loading Backup File ---")
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
        
        if url.pathExtension.lowercased() == "lzfse" {
            print("Decompressing LZFSE file...")
            do {
                let decompressedData = try data.decompressed(using: .lzfse)
                print("Decompressed from \(data.count) to \(decompressedData.count) bytes")
                return decompressedData
            } catch {
                print("Decompression failed: \(error)")
                throw NSError(domain: "DecompressionError", code: 500, userInfo: [NSLocalizedDescriptionKey: "압축 해제에 실패했습니다: \(error.localizedDescription)"])
            }
        }
        
        return data
    }
    
    private static func loadCompleteBackup(url: URL) throws -> CompleteBackupData {
        let data = try loadBackupData(url: url)
        
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
    
    private static func loadMultiAccountBackup(url: URL) throws -> MultiAccountBackupData {
        let data = try loadBackupData(url: url)
        
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("JSON keys: \(Array(jsonObject.keys))")
            
            if let accounts = jsonObject["accounts"] as? [String: Any] {
                print("Accounts count in JSON: \(accounts.count)")
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
            let multiAccountBackup = try decoder.decode(MultiAccountBackupData.self, from: data)
            print("✅ Successfully loaded backup: \(multiAccountBackup.accounts.count) accounts")
            print("Export date: \(multiAccountBackup.exportDate)")
            print("Version: \(multiAccountBackup.version)")
            print("---------------------------")
            return multiAccountBackup
        } catch {
            print("❌ Backup decoding failed: \(error)")
            throw NSError(domain: "BackupLoadError", code: 400, userInfo: [NSLocalizedDescriptionKey: "백업 파일 형식이 올바르지 않습니다: \(error.localizedDescription)"])
        }
    }
    
    @MainActor
    static func generatePreview(from backupURL: URL) throws -> PreviewResult {
        do {
            let multiAccountBackup = try loadMultiAccountBackup(url: backupURL)
            return try generateMultiAccountPreview(multiAccountBackup: multiAccountBackup)
        } catch {
            print("Backup loading failed, trying legacy format...")
            let completeBackup = try loadCompleteBackup(url: backupURL)
            return try generateLegacyPreview(completeBackup: completeBackup)
        }
    }
    
    @MainActor
    private static func generateMultiAccountPreview(multiAccountBackup: MultiAccountBackupData) throws -> PreviewResult {
        guard let currentUserId = accountManager.currentUserId else {
            throw NSError(domain: "NoCurrentUser", code: 400, userInfo: [NSLocalizedDescriptionKey: "현재 로그인된 사용자가 없습니다."])
        }
        
        let currentFriends = try loadFriends()
        let currentHistory = loadAllFriendHistory()
        
        print("--- Multi-Account Preview Generation ---")
        print("Backup accounts: \(multiAccountBackup.accounts.count)")
        print("Current user: \(currentUserId)")
        
        var addedCount = 0
        var updatedCount = 0
        var historyAddedCount = 0
        var historyFriendsCount = 0
        var backupFriendsCount = 0
        
        for (accountId, accountData) in multiAccountBackup.accounts {
            print("Processing account \(accountId): \(accountData.friends.count) friends, \(accountData.historyCount) history entries")
            
            backupFriendsCount += accountData.friends.count
            
            // 친구 목록 변경사항 확인
            let currentFriendsDict = Dictionary(uniqueKeysWithValues: currentFriends.map { ($0.id, $0) })
            
            for backupFriend in accountData.friends {
                if let currentFriend = currentFriendsDict[backupFriend.id] {
                    if shouldUpdateFriend(current: currentFriend, backup: backupFriend) {
                        updatedCount += 1
                    }
                } else {
                    addedCount += 1
                }
            }
            
            // 친구 기록 변경사항 확인
            for (friendId, backupHistories) in accountData.friendHistory {
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
                }
            }
        }
        
        print("Multi-account preview result: Added \(addedCount), Updated \(updatedCount), History Added \(historyAddedCount), History Friends \(historyFriendsCount)")
        print("-------------------------")
        
        return PreviewResult(
            addedCount: addedCount,
            updatedCount: updatedCount,
            backupFriendsCount: backupFriendsCount,
            currentFriendsCount: currentFriends.count,
            historyAddedCount: historyAddedCount,
            historyFriendsCount: historyFriendsCount
        )
    }
    
    @MainActor
    private static func generateLegacyPreview(completeBackup: CompleteBackupData) throws -> PreviewResult {
        let currentFriends = try loadFriends()
        let currentHistory = loadAllFriendHistory()
        
        print("--- Legacy Preview Generation ---")
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
        
        print("Legacy preview result: Added \(addedCount), Updated \(updatedCount), History Added \(historyAddedCount), History Friends \(historyFriendsCount)")
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
    
    @MainActor
    static func importCompleteBackup(from backupURL: URL) throws -> CompleteBackupResult {
        do {
            let multiAccountBackup = try loadMultiAccountBackup(url: backupURL)
            return try importMultiAccountBackup(multiAccountBackup: multiAccountBackup)
        } catch {
            print("Backup loading failed, trying legacy format...")
            let completeBackup = try loadCompleteBackup(url: backupURL)
            return try importLegacyBackup(completeBackup: completeBackup)
        }
    }
    
    @MainActor
    private static func importMultiAccountBackup(multiAccountBackup: MultiAccountBackupData) throws -> CompleteBackupResult {
        guard let currentUserId = accountManager.currentUserId else {
            throw NSError(domain: "NoCurrentUser", code: 400, userInfo: [NSLocalizedDescriptionKey: "현재 로그인된 사용자가 없습니다."])
        }
        
        print("--- Multi-Account Import ---")
        print("Importing \(multiAccountBackup.accounts.count) accounts")
        
        let currentFriends = try loadFriends()
        var totalImportedHistory = 0
        var friendMergeResult: MergeResult?
        
        if let currentAccountData = multiAccountBackup.accounts[currentUserId] {
            print("Found data for current account \(currentUserId)")
            friendMergeResult = mergeFriends(current: currentFriends, backup: currentAccountData.friends)
            saveFriends(friendMergeResult!.mergedFriends)
            totalImportedHistory += importFriendHistory(currentAccountData.friendHistory)
        }
        
        var allBackupFriends: [Friend] = []
        var allBackupHistory: [String: [FriendHistory]] = [:]
        
        for (accountId, accountData) in multiAccountBackup.accounts {
            if accountId != currentUserId {
                print("Processing account \(accountId): \(accountData.friends.count) friends")
                
                for friend in accountData.friends {
                    if !allBackupFriends.contains(where: { $0.id == friend.id }) {
                        allBackupFriends.append(friend)
                    }
                }
                
                for (friendId, histories) in accountData.friendHistory {
                    if allBackupHistory[friendId] == nil {
                        allBackupHistory[friendId] = []
                    }
                    
                    let existingIds = Set(allBackupHistory[friendId]!.map { $0.id })
                    for history in histories {
                        if !existingIds.contains(history.id) {
                            allBackupHistory[friendId]!.append(history)
                        }
                    }
                }
            }
        }
        
        if !allBackupFriends.isEmpty {
            let currentMergedFriends = friendMergeResult?.mergedFriends ?? currentFriends
            let additionalMergeResult = mergeFriends(current: currentMergedFriends, backup: allBackupFriends)
            saveFriends(additionalMergeResult.mergedFriends)
            
            if friendMergeResult == nil {
                friendMergeResult = additionalMergeResult
            } else {
                friendMergeResult = MergeResult(
                    mergedFriends: additionalMergeResult.mergedFriends,
                    addedCount: friendMergeResult!.addedCount + additionalMergeResult.addedCount,
                    updatedCount: friendMergeResult!.updatedCount + additionalMergeResult.updatedCount,
                    unchangedCount: friendMergeResult!.unchangedCount + additionalMergeResult.unchangedCount
                )
            }
        }
        
        if !allBackupHistory.isEmpty {
            totalImportedHistory += importFriendHistory(allBackupHistory)
        }
        
        print("Multi-account import completed")
        
        return CompleteBackupResult(
            friendMergeResult: friendMergeResult ?? MergeResult(mergedFriends: [], addedCount: 0, updatedCount: 0, unchangedCount: 0),
            historyImported: totalImportedHistory,
            isCompleteBackup: true
        )
    }
    
    @MainActor
    private static func importLegacyBackup(completeBackup: CompleteBackupData) throws -> CompleteBackupResult {
        let currentFriends = try loadFriends()
        
        let friendMergeResult = mergeFriends(current: currentFriends, backup: completeBackup.friends)
        saveFriends(friendMergeResult.mergedFriends)
        
        let historyImported = importFriendHistory(completeBackup.friendHistory)
        
        return CompleteBackupResult(
            friendMergeResult: friendMergeResult,
            historyImported: historyImported,
            isCompleteBackup: true
        )
    }
    
    @MainActor
    private static func importFriendHistory(_ historyData: [String: [FriendHistory]]) -> Int {
        guard let accountDirectory = accountManager.getCurrentAccountDirectory() else { return 0 }
        
        let historyFileURL = accountDirectory.appendingPathComponent("friendHistory.json")
        var existingHistory = loadAllFriendHistory()
        var importedCount = 0
        
        for (friendId, histories) in historyData {
            let existingHistories = existingHistory[friendId] ?? []
            let existingIds = Set(existingHistories.map { $0.id })
            
            var mergedHistories = existingHistories
            
            for history in histories {
                if !existingIds.contains(history.id) {
                    mergedHistories.append(history)
                    importedCount += 1
                }
            }
            
            mergedHistories.sort { $0.date > $1.date }
            existingHistory[friendId] = mergedHistories
        }
        
        do {
            let directory = historyFileURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                print("📁 [importFriendHistory] Created directory: \(directory.path)")
            }
            
            let data = try JSONEncoder().encode(existingHistory)
            try data.write(to: historyFileURL)
            print("Imported \(importedCount) friend history entries")
        } catch {
            print("Failed to save friend history: \(error)")
        }
        
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
    
    @MainActor
    static func exportCompleteBackup() -> URL? {
        return exportMultiAccountBackup()
    }
    
    @MainActor
    static func exportMultiAccountBackup() -> URL? {
        guard let currentUserId = accountManager.currentUserId else {
            print("No current user ID")
            return nil
        }
        
        do {
            cleanupOldBackupFiles()
            
            let fileManager = FileManager.default
            var accounts: [String: AccountData] = [:]
            var totalFriends = 0
            var totalHistoryEntries = 0
            
            if let currentAccountData = loadCurrentAccountData() {
                accounts[currentUserId] = currentAccountData
                totalFriends = currentAccountData.friendsCount
                totalHistoryEntries = currentAccountData.historyCount
                print("Loaded current account \(currentUserId): \(currentAccountData.friendsCount) friends, \(currentAccountData.historyCount) history entries")
            } else {
                let accountInfo = accountManager.availableAccounts.first { $0.userId == currentUserId }
                let userName = accountInfo?.userName ?? "Current User"
                let lastUpdated = accountInfo?.lastLoginDate ?? Date()
                
                let emptyAccountData = AccountData(
                    userId: currentUserId,
                    userName: userName,
                    lastUpdated: lastUpdated,
                    friendsCount: 0,
                    historyCount: 0,
                    friends: [],
                    friendHistory: [:]
                )
                
                accounts[currentUserId] = emptyAccountData
                print("Created empty account data for current user \(currentUserId)")
            }
            
            if let accountsBaseDirectory = AccountManager.getAccountsBaseDirectory(),
               fileManager.fileExists(atPath: accountsBaseDirectory.path) {
                let accountDirectories = try fileManager.contentsOfDirectory(at: accountsBaseDirectory, includingPropertiesForKeys: nil)
                
                for accountDir in accountDirectories {
                    let userId = accountDir.lastPathComponent
                    
                    if userId == currentUserId {
                        continue
                    }
                    
                    let friendCacheURL = accountDir.appendingPathComponent("friendCache.json")
                    var friends: [Friend] = []
                    
                    if fileManager.fileExists(atPath: friendCacheURL.path) {
                        let friendsData = try Data(contentsOf: friendCacheURL)
                        friends = try JSONDecoder().decode([Friend].self, from: friendsData)
                    }
                    
                    let historyURL = accountDir.appendingPathComponent("friendHistory.json")
                    var friendHistory: [String: [FriendHistory]] = [:]
                    
                    if fileManager.fileExists(atPath: historyURL.path) {
                        let historyData = try Data(contentsOf: historyURL)
                        friendHistory = try JSONDecoder().decode([String: [FriendHistory]].self, from: historyData)
                    }
                    
                    let accountInfo = accountManager.availableAccounts.first { $0.userId == userId }
                    let userName = accountInfo?.userName ?? "Unknown User"
                    let lastUpdated = accountInfo?.lastLoginDate ?? Date()
                    
                    let historyCount = friendHistory.values.reduce(0) { $0 + $1.count }
                    
                    let accountData = AccountData(
                        userId: userId,
                        userName: userName,
                        lastUpdated: lastUpdated,
                        friendsCount: friends.count,
                        historyCount: historyCount,
                        friends: friends,
                        friendHistory: friendHistory
                    )
                    
                    accounts[userId] = accountData
                    totalFriends += friends.count
                    totalHistoryEntries += historyCount
                    
                    print("Loaded additional account \(userId): \(friends.count) friends, \(historyCount) history entries")
                }
            }
            
            let metadata = BackupMetadata(
                totalFriends: totalFriends,
                totalHistoryEntries: totalHistoryEntries,
                appVersion: BundleUtil.appVersion,
                deviceType: "iOS"
            )
            
            let multiAccountBackup = MultiAccountBackupData(
                version: "2.0",
                exportDate: Date(),
                exportedBy: currentUserId,
                totalAccounts: accounts.count,
                accounts: accounts,
                metadata: metadata
            )
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .formatted(.iso8601Full)
            let backupData = try encoder.encode(multiAccountBackup)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
            
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
            }
            
            let originalSize = backupData.count
            if let compressedData = try? backupData.compressed(using: .lzfse) {
                let compressedSize = compressedData.count
                let compressionRatio = Double(compressedSize) / Double(originalSize)
                
                if compressionRatio < 0.7 {
                    let filename = "Orbit_Backup_\(timestamp).json.lzfse"
                    let exportURL = documentsDirectory.appendingPathComponent(filename)
                    
                    try compressedData.write(to: exportURL)
                    try setFileAttributes(for: exportURL)
                    
                    print("Backup exported (compressed): \(accounts.count) accounts, \(totalFriends) friends, \(totalHistoryEntries) history entries")
                    print("Original size: \(ByteCountFormatter().string(fromByteCount: Int64(originalSize)))")
                    print("Compressed size: \(ByteCountFormatter().string(fromByteCount: Int64(compressedSize)))")
                    print("Compression ratio: \(String(format: "%.1f", compressionRatio * 100))%")
                    return exportURL
                }
            }
            
            let filename = "Orbit_Backup_\(timestamp).json"
            let exportURL = documentsDirectory.appendingPathComponent(filename)
            
            try backupData.write(to: exportURL)
            try setFileAttributes(for: exportURL)
            
            print("Backup exported (uncompressed): \(accounts.count) accounts, \(totalFriends) friends, \(totalHistoryEntries) history entries")
            print("File size: \(ByteCountFormatter().string(fromByteCount: Int64(originalSize)))")
            return exportURL
            
        } catch {
            print("Error exporting backup: \(error)")
            return nil
        }
    }
    
    @MainActor
    private static func loadCurrentAccountData() -> AccountData? {
        guard let currentUserId = accountManager.currentUserId else { return nil }
        
        do {
            let friends = try loadFriends()
            let friendHistory = loadAllFriendHistory()
            let historyCount = friendHistory.values.reduce(0) { $0 + $1.count }
            
            let accountInfo = accountManager.availableAccounts.first { $0.userId == currentUserId }
            let userName = accountInfo?.userName ?? "Current User"
            let lastUpdated = accountInfo?.lastLoginDate ?? Date()
            
            return AccountData(
                userId: currentUserId,
                userName: userName,
                lastUpdated: lastUpdated,
                friendsCount: friends.count,
                historyCount: historyCount,
                friends: friends,
                friendHistory: friendHistory
            )
        } catch {
            print("Error loading current account data: \(error)")
            return nil
        }
    }

    // MARK: - Reset Functions
    
    @MainActor
    static func resetAllAccountsData(restoreCurrentUser: User? = nil) throws {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "FileManagerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Documents 디렉토리를 찾을 수 없습니다."])
        }
        
        let accountsDirectory = documentsDirectory.appendingPathComponent("accounts")
        
        if FileManager.default.fileExists(atPath: accountsDirectory.path) {
            try FileManager.default.removeItem(at: accountsDirectory)
            print("✅ All accounts data deleted successfully")
        }
        
        deleteLegacyFiles()
        accountManager.resetAllAccounts()
        
        if let currentUser = restoreCurrentUser {
            print("🔄 [resetAllAccountsData] Restoring current user after reset: \(currentUser.displayName)")
            accountManager.setCurrentUser(currentUser)
        }
    }

    static func resetAllAccountsHistory() throws {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "FileManagerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Documents 디렉토리를 찾을 수 없습니다."])
        }
        
        let accountsDirectory = documentsDirectory.appendingPathComponent("accounts")
        
        if FileManager.default.fileExists(atPath: accountsDirectory.path) {
            let accountDirectories = try FileManager.default.contentsOfDirectory(at: accountsDirectory, includingPropertiesForKeys: nil)
            
            for accountDir in accountDirectories where accountDir.hasDirectoryPath {
                let historyFile = accountDir.appendingPathComponent("friendHistory.json")
                if FileManager.default.fileExists(atPath: historyFile.path) {
                    try FileManager.default.removeItem(at: historyFile)
                    print("✅ Deleted friend history for account: \(accountDir.lastPathComponent)")
                }
            }
        }
        
        let legacyHistoryFile = documentsDirectory.appendingPathComponent("friendHistory.json")
        if FileManager.default.fileExists(atPath: legacyHistoryFile.path) {
            try FileManager.default.removeItem(at: legacyHistoryFile)
            print("✅ Deleted legacy friend history")
        }
    }
    
    private static func deleteLegacyFiles() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let legacyFiles = [
            "friendCache.json",
            "friendHistory.json"
        ]
        
        for fileName in legacyFiles {
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    print("✅ Deleted legacy file: \(fileName)")
                } catch {
                    print("❌ Failed to delete legacy file \(fileName): \(error)")
                }
            }
        }
    }

    // MARK: - Helper Functions
    
    private static func cleanupOldBackupFiles() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            
            let backupFiles = files.filter { url in
                let filename = url.lastPathComponent
                return (filename.hasPrefix("Orbit_Backup_") && 
                       (filename.hasSuffix(".json") || filename.hasSuffix(".json.lzfse")))
            }
            
            if !backupFiles.isEmpty {
                print("🗑️ [cleanupOldBackupFiles] Found \(backupFiles.count) old backup files to clean up")
                
                for file in backupFiles {
                    try FileManager.default.removeItem(at: file)
                    print("🗑️ [cleanupOldBackupFiles] Deleted: \(file.lastPathComponent)")
                }
                
                print("✅ [cleanupOldBackupFiles] Cleaned up \(backupFiles.count) old backup files")
            } else {
                print("ℹ️ [cleanupOldBackupFiles] No old backup files found")
            }
        } catch {
            print("❌ [cleanupOldBackupFiles] Error cleaning up old backup files: \(error)")
        }
    }
    
    private static func setFileAttributes(for url: URL) throws {
        let attributes: [FileAttributeKey: Any] = [
            .posixPermissions: 0o644
        ]
        
        try FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
        print("✅ File attributes set for: \(url.lastPathComponent)")
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
    
    @MainActor
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
        var lastModified: Date?
        if let cacheURL = cacheURL,
           let attributes = try? FileManager.default.attributesOfItem(atPath: cacheURL.path),
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
