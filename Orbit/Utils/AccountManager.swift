//
//  AccountManager.swift
//  Orbit
//
//  Created by NoriDev on 7/10/25.
//

import Foundation
import VRCKit

@MainActor
class AccountManager: ObservableObject {
    static let shared = AccountManager()
    
    @Published var currentUserId: String?
    @Published var availableAccounts: [AccountInfo] = []
    
    private let userDefaults = UserDefaults.standard
    private let currentUserIdKey = "currentUserId"
    private let accountsKey = "availableAccounts"
    
    struct AccountInfo: Codable, Identifiable {
        let id: String
        let userId: String
        let userName: String
        let lastLoginDate: Date
        let createdDate: Date
        
        var accountDirectory: URL? {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            let accountsDirectory = documentsDirectory.appendingPathComponent("accounts")
            return accountsDirectory.appendingPathComponent(userId)
        }
    }
    
    private init() {
        loadStoredData()
    }
    
    // MARK: - Public Methods
    
    func setCurrentUser(_ user: User) {
        let userId = user.id
        
        print("👤 [setCurrentUser] Setting current user: \(user.displayName) (ID: \(userId))")
        
        // 계정 변경 감지
        if currentUserId != userId {
            handleAccountSwitch(from: currentUserId, to: userId)
        }
        
        currentUserId = userId
        updateAccountInfo(user)
        saveCurrentUserId()
        
        print("👤 [setCurrentUser] Current user set successfully")
    }
    
    func getCurrentAccountDirectory() -> URL? {
        guard let userId = currentUserId else { 
            print("❌ [getCurrentAccountDirectory] No current user ID")
            return nil 
        }
        
        let directory = Self.getAccountDirectory(for: userId)
        print("📁 [getCurrentAccountDirectory] Current user: \(userId)")
        print("📁 [getCurrentAccountDirectory] Directory path: \(directory?.path ?? "nil")")
        
        return directory
    }
    
    func getAccountDirectory(for userId: String) -> URL? {
        return Self.getAccountDirectory(for: userId)
    }
    
    // MARK: - Reset Methods
    
    func resetAllAccounts() {
        print("🗑️ [resetAllAccounts] Clearing all account information")
        
        currentUserId = nil
        availableAccounts = []
        
        userDefaults.removeObject(forKey: currentUserIdKey)
        userDefaults.removeObject(forKey: accountsKey)
        
        print("✅ [resetAllAccounts] All account information cleared")
    }
    
    func resetAccountsExceptCurrent() {
        guard let currentUserId = currentUserId else {
            print("⚠️ [resetAccountsExceptCurrent] No current user ID")
            return
        }
        
        print("🗑️ [resetAccountsExceptCurrent] Keeping only current account: \(currentUserId)")
        
        availableAccounts = availableAccounts.filter { $0.userId == currentUserId }
        saveAccountsInfo()
        
        print("✅ [resetAccountsExceptCurrent] Removed other accounts, kept current account")
    }
    
    // MARK: - Private Methods
    
    private func loadStoredData() {
        currentUserId = userDefaults.string(forKey: currentUserIdKey)
        
        if let data = userDefaults.data(forKey: accountsKey),
           let accounts = try? JSONDecoder().decode([AccountInfo].self, from: data) {
            availableAccounts = accounts
        }
    }
    
    private func saveCurrentUserId() {
        if let userId = currentUserId {
            userDefaults.set(userId, forKey: currentUserIdKey)
        } else {
            userDefaults.removeObject(forKey: currentUserIdKey)
        }
    }
    
    private func updateAccountInfo(_ user: User) {
        let userId = user.id
        let now = Date()
        
        if let index = availableAccounts.firstIndex(where: { $0.userId == userId }) {
            availableAccounts[index] = AccountInfo(
                id: userId,
                userId: userId,
                userName: user.displayName,
                lastLoginDate: now,
                createdDate: availableAccounts[index].createdDate
            )
        } else {
            let newAccount = AccountInfo(
                id: userId,
                userId: userId,
                userName: user.displayName,
                lastLoginDate: now,
                createdDate: now
            )
            availableAccounts.append(newAccount)
        }
        
        saveAccountsInfo()
        createAccountDirectoryIfNeeded(for: userId)
    }
    
    private func saveAccountsInfo() {
        if let data = try? JSONEncoder().encode(availableAccounts) {
            userDefaults.set(data, forKey: accountsKey)
        }
    }
    
    private func createAccountDirectoryIfNeeded(for userId: String) {
        guard let accountDir = Self.getAccountDirectory(for: userId) else { return }
        
        if !FileManager.default.fileExists(atPath: accountDir.path) {
            do {
                try FileManager.default.createDirectory(at: accountDir, withIntermediateDirectories: true)
                print("Created account directory: \(accountDir.path)")
            } catch {
                print("Failed to create account directory: \(error)")
            }
        }
    }
    
    private func handleAccountSwitch(from oldUserId: String?, to newUserId: String) {
        print("Account switch detected: \(oldUserId ?? "nil") → \(newUserId)")
    }
    
    // MARK: - Static Methods

    static func getAccountDirectory(for userId: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        return documentsDirectory
            .appendingPathComponent("accounts")
            .appendingPathComponent(userId)
    }
    
    static func getAccountsBaseDirectory() -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        return documentsDirectory.appendingPathComponent("accounts")
    }
    
    // MARK: - Legacy Data Recovery
    
    func checkAndMigrateLegacyData() {
        guard currentUserId != nil else {
            print("⚠️ [checkAndMigrateLegacyData] No current user ID")
            return
        }
        
        print("🔍 [checkAndMigrateLegacyData] Checking for legacy data to migrate")
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let legacyFriendCacheURL = documentsDirectory.appendingPathComponent("friendCache.json")
        
        var migrationPerformed = false
        
        if FileManager.default.fileExists(atPath: legacyFriendCacheURL.path) {
            print("📁 [checkAndMigrateLegacyData] Found legacy friendCache.json, migrating...")
            
            if let accountDir = getCurrentAccountDirectory() {
                let newFriendCacheURL = accountDir.appendingPathComponent("friendCache.json")
                
                if !FileManager.default.fileExists(atPath: newFriendCacheURL.path) {
                    do {
                        try FileManager.default.copyItem(at: legacyFriendCacheURL, to: newFriendCacheURL)
                        print("✅ [checkAndMigrateLegacyData] Copied friendCache.json to account directory")
                        migrationPerformed = true
                        
                        try FileManager.default.removeItem(at: legacyFriendCacheURL)
                        print("🗑️ [checkAndMigrateLegacyData] Removed legacy friendCache.json")
                        
                    } catch {
                        print("❌ [checkAndMigrateLegacyData] Failed to migrate friendCache.json: \(error)")
                    }
                } else {
                    print("⚠️ [checkAndMigrateLegacyData] Account-specific friendCache.json already exists, skipping migration")
                }
            }
        }
        
        if migrateLegacyFriendHistory() {
            migrationPerformed = true
        }
        
        if migrationPerformed {
            print("✅ [checkAndMigrateLegacyData] Legacy data migration completed")
        } else {
            print("ℹ️ [checkAndMigrateLegacyData] No legacy data found to migrate")
        }
    }
    
    private func migrateLegacyFriendHistory() -> Bool {
        guard let accountDir = getCurrentAccountDirectory() else { return false }
        
        let userDefaults = UserDefaults.standard
        let allHistoryKey = "allFriendHistoryKeys"
        let historyFileURL = accountDir.appendingPathComponent("friendHistory.json")
        
        if FileManager.default.fileExists(atPath: historyFileURL.path) {
            print("⚠️ [migrateLegacyFriendHistory] Account-specific friend history already exists, skipping migration")
            return false
        }
        
        if let allKeys = userDefaults.stringArray(forKey: allHistoryKey), !allKeys.isEmpty {
            print("📁 [migrateLegacyFriendHistory] Found legacy friend history data, migrating...")
            
            var allHistory: [String: [FriendHistory]] = [:]
            var successfulMigrations = 0
            
            for key in allKeys {
                if let data = userDefaults.data(forKey: key),
                   let histories = try? JSONDecoder().decode([FriendHistory].self, from: data) {
                    let friendId = key.replacingOccurrences(of: "friendHistory_", with: "")
                    allHistory[friendId] = histories
                    successfulMigrations += 1
                }
            }
            
            if !allHistory.isEmpty {
                do {
                    let data = try JSONEncoder().encode(allHistory)
                    try data.write(to: historyFileURL)
                    print("✅ [migrateLegacyFriendHistory] Migrated friend history to account directory: \(successfulMigrations)/\(allKeys.count) entries")
                    
                    for key in allKeys {
                        userDefaults.removeObject(forKey: key)
                    }
                    userDefaults.removeObject(forKey: allHistoryKey)
                    
                    return true
                    
                } catch {
                    print("❌ [migrateLegacyFriendHistory] Failed to migrate friend history: \(error)")
                    return false
                }
            }
        }
        
        return false
    }
}
