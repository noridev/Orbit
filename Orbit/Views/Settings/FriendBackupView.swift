//
//  FriendBackupView.swift
//  Orbit
//
//  Created by NoriDev on 7/9/25.
//

import SwiftUI
import UniformTypeIdentifiers
import VRCKit

struct FriendBackupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) var appVM
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingFilePicker = false
    @State private var showingPreview = false
    @State private var showingConfirmation = false
    @State private var showingCompleteBackupPicker = false
    @State private var showingCompleteBackupConfirmation = false
    @State private var showingShareSheet = false
    @State private var showingResetMenu = false
    @State private var showingResetConfirmation = false
    @State private var resetType: ResetType = .all
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var previewResult: FriendCacheManager.PreviewResult?
    @State private var completeBackupResult: FriendCacheManager.CompleteBackupResult?
    @State private var selectedBackupURL: URL?
    @State private var backupType: BackupType = .friendsOnly
    @State private var exportedFileURL: URL?
    @State private var dataStatus = FriendCacheManager.DataStatus(friendsCount: 0, friendsDataSize: 0, historyCount: 0, historyDataSize: 0, totalDataSize: 0, lastModified: nil)
    @State private var accountManager = AccountManager.shared
    
    enum BackupType {
        case friendsOnly
        case complete
    }
    
    enum ResetType: CaseIterable {
        case all
        case historyOnly
        
        var title: String {
            switch self {
            case .all: return "모두 재설정"
            case .historyOnly: return "친구 기록만 재설정"
            }
        }
        
        var description: String {
            switch self {
            case .all: return "모든 계정의 친구 데이터와 기록을 삭제합니다."
            case .historyOnly: return "모든 계정의 친구 기록을 삭제합니다. (친구 데이터는 유지됨)"
            }
        }
        
        var icon: String {
            switch self {
            case .all: return "trash.fill"
            case .historyOnly: return "clock.arrow.2.circlepath"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .red
            case .historyOnly: return .orange
            }
        }
    }
    
    var body: some View {
        List {
            headerSection
            accountInfoSection
            dataStatusSection
            dataManagementSection
            importantNoticeSection
        }
        .navigationTitle("친구 데이터 관리")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshDataStatus()
        }
        .task {
            refreshDataStatus()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                SafeShareSheet(fileURL: url)
            }
        }
        .sheet(isPresented: $showingResetMenu) {
            ResetSelectionSheet(
                resetType: $resetType,
                onConfirm: {
                    showingResetMenu = false
                    showingResetConfirmation = true
                },
                onCancel: {
                    showingResetMenu = false
                }
            )
        }
        .alert("데이터 재설정 확인", isPresented: $showingResetConfirmation) {
            Button("재설정", role: .destructive) {
                performReset(type: resetType)
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("\(resetType.description)\n\n이 작업은 되돌릴 수 없습니다.")
        }
        .sheet(isPresented: $showingPreview) {
            if let previewResult = previewResult {
                PreviewSheet(
                    previewResult: previewResult,
                    onConfirm: {
                        showingPreview = false
                        if let url = selectedBackupURL {
                            importFriendData(from: url)
                        }
                    },
                    onCancel: {
                        showingPreview = false
                        selectedBackupURL = nil
                        self.previewResult = nil
                    }
                )
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [
                .json,
                UTType(filenameExtension: "lzfse") ?? UTType.data
            ],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedBackupURL = url
                    generatePreview(for: url)
                }
            case .failure(let error):
                alertTitle = "오류 발생"
                alertMessage = "파일 선택 오류: \(error.localizedDescription)"
                showingAlert = true
            }
        }
        .alert("가져올 데이터 없음", isPresented: $showingConfirmation) {
            Button("가져오기") {
                if let url = selectedBackupURL {
                    importFriendData(from: url)
                }
            }
            Button("취소", role: .cancel) {
                selectedBackupURL = nil
            }
        } message: {
            Text("모든 데이터가 최신입니다. 그래도 가져오시겠습니까?")
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("확인") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        Section {
            VStack(spacing: 16) {
                headerIcon
                headerContent
            }
            .frame(maxWidth: .infinity)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    private var headerIcon: some View {
        Image(systemName: "person.2.circle.fill")
            .font(.system(size: 48))
            .foregroundStyle(.blue.gradient)
    }
    
    private var headerContent: some View {
        VStack(spacing: 8) {
            Text("친구 데이터 관리")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("모든 계정의 친구 데이터를 안전하게 백업하고 복원할 수 있습니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var accountInfoSection: some View {
        Section {
            accountInfoContent
        } header: {
            Text("계정 정보")
        }
    }
    
    private var accountInfoContent: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("현재 계정")
                        .font(.headline)
                    if let currentAccount = accountManager.availableAccounts.first(where: { $0.userId == accountManager.currentUserId }) {
                        Text(currentAccount.userName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("총 계정")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(accountManager.availableAccounts.count)")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            
            if accountManager.availableAccounts.count > 1 {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("등록된 계정")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(accountManager.availableAccounts.prefix(3)) { account in
                        HStack {
                            Image(systemName: account.userId == accountManager.currentUserId ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(account.userId == accountManager.currentUserId ? .green : .secondary)
                                .font(.caption)
                            
                            Text(account.userName)
                                .font(.caption)
                                .foregroundColor(account.userId == accountManager.currentUserId ? .primary : .secondary)
                            
                            Spacer()
                            
                            Text(RelativeDateTimeFormatter().localizedString(for: account.lastLoginDate, relativeTo: Date()))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if accountManager.availableAccounts.count > 3 {
                        Text("그 외 \(accountManager.availableAccounts.count - 3)개 계정")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
            }
        }
        .padding(8)
    }
    
    private var dataStatusSection: some View {
        Section {
            dataStatusContent
        } header: {
            Text("데이터 정보")
        }
    }
    
    private var dataStatusContent: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("데이터 상태")
                        .font(.headline)
                    Text("현재 저장된 친구 데이터 정보")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "externaldrive")
                        .foregroundColor(.purple)
                        .frame(width: 16, height: 16)
                    Text("총 데이터 크기")
                    Spacer()
                    Text(dataStatus.formattedTotalSize)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .font(.subheadline)
                
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(.blue)
                        .frame(width: 16, height: 16)
                    Text("친구 목록")
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(dataStatus.friendsCount)명")
                        Text("(\(dataStatus.formattedFriendsSize))")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .font(.subheadline)
                
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.green)
                        .frame(width: 16, height: 16)
                    Text("친구 기록")
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(dataStatus.historyCount)개")
                        Text("(\(dataStatus.formattedHistorySize))")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .font(.subheadline)
                
                if let lastModified = dataStatus.lastModified {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.orange)
                            .frame(width: 16, height: 16)
                        Text("마지막 업데이트")
                        Spacer()
                        Text(RelativeDateTimeFormatter().localizedString(for: lastModified, relativeTo: Date()))
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding(8)
    }
    
    private var dataManagementSection: some View {
        Section {
            exportButton
            importButton
            resetButton
        } header: {
            Text("데이터 관리")
        } footer: {
            footerContent
        }
    }
    
    private var exportButton: some View {
        Button {
            exportFriendData()
        } label: {
            BackupActionRow(
                icon: "square.and.arrow.up",
                title: "백업 생성",
                subtitle: "친구 목록과 기록을 파일로 저장",
                color: .blue,
                isLoading: isExporting
            )
        }
        .disabled(isExporting || isImporting)
    }
    
    private var importButton: some View {
        Button {
            showingFilePicker = true
        } label: {
            BackupActionRow(
                icon: "square.and.arrow.down",
                title: "백업 복원",
                subtitle: "백업 파일에서 데이터 가져오기",
                color: .green,
                isLoading: isImporting
            )
        }
        .disabled(isExporting || isImporting)
    }
    
    private var resetButton: some View {
        Button {
            showingResetMenu = true
        } label: {
            BackupActionRow(
                icon: "trash.fill",
                title: "데이터 재설정",
                subtitle: "모든 계정의 데이터 재설정",
                color: .red,
                isLoading: false
            )
        }
        .disabled(isExporting || isImporting)
    }
    
    private var footerContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .frame(width: 16, height: 16)
                Text("백업에는 모든 계정의 친구 목록과 기록이 포함됩니다.")
            }
            
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.merge")
                    .foregroundColor(.green)
                    .frame(width: 16, height: 16)
                Text("백업을 복원하면 기존 데이터와 자동으로 병합됩니다.")
            }
            
            HStack(spacing: 6) {
                Image(systemName: "archivebox")
                    .foregroundColor(.purple)
                    .frame(width: 16, height: 16)
                Text("대용량 백업은 자동으로 압축되어 저장됩니다.")
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    
    private var importantNoticeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                noticeHeader
                noticeItems
            }
            .padding(.vertical, 8)
        }
    }
    
    private var noticeHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("진행 전 안내")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
    
    private var noticeItems: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("• 백업 파일은 개인정보를 포함하므로 안전하게 보관하세요.")
            Text("• 정기적인 백업으로 데이터 손실을 방지하세요.")
            Text("• 기기 변경 시 백업 파일로 데이터를 쉽게 이전할 수 있습니다.")
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
    }
    
    // MARK: - Private Methods
    
    private func exportFriendData() {
        isExporting = true
        
        Task {
            let exportURL = FriendCacheManager.exportCompleteBackup()
            await MainActor.run {
                isExporting = false
                if let exportURL = exportURL {
                    exportedFileURL = exportURL
                    showingShareSheet = true
                } else {
                    alertTitle = "백업을 생성할 수 없음"
                    alertMessage = "친구 데이터가 없거나 오류가 발생했습니다."
                    showingAlert = true
                }
            }
        }
    }
    
    private func generatePreview(for url: URL) {
        isImporting = true
        
        Task {
            let success = url.startAccessingSecurityScopedResource()
            defer {
                if success {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                let preview = try FriendCacheManager.generatePreview(from: url)
                
                await MainActor.run {
                    isImporting = false
                    previewResult = preview
                    
                    if preview.totalChanges == 0 {
                        showingConfirmation = true
                    } else {
                        showingPreview = true
                    }
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    alertTitle = "데이터 가져오기가 실패함"
                    alertMessage = "백업 파일을 불러오는 중 문제 발생: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func importFriendData(from url: URL) {
        isImporting = true
        
        Task {
            let success = url.startAccessingSecurityScopedResource()
            defer {
                if success {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                print("🔄 Starting complete backup import...")
                let result = try FriendCacheManager.importCompleteBackup(from: url)
                
                await MainActor.run {
                    isImporting = false
                    
                    let friendMessage = "추가된 친구: \(result.friendMergeResult.addedCount)명\n업데이트된 친구: \(result.friendMergeResult.updatedCount)명"
                    let historyMessage = "추가된 기록: \(result.historyImported)개"
                    
                    alertTitle = "데이터 복원이 완료됨"
                    alertMessage = "\(friendMessage)\n\(historyMessage)"
                    showingAlert = true
                    
                    selectedBackupURL = nil
                    previewResult = nil
                    refreshDataStatus()
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    alertTitle = "데이터 복원이 실패함"
                    alertMessage = "\(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func refreshDataStatus() {
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            await MainActor.run {
                dataStatus = FriendCacheManager.getDataStatus()
                print("📊 [refreshDataStatus] Data status updated: \(dataStatus.friendsCount) friends, \(dataStatus.historyCount) history")
            }
        }
    }
    
    private func performReset(type: ResetType) {
        Task {
            do {
                switch type {
                case .all:
                    try await FriendCacheManager.resetAllAccountsData(restoreCurrentUser: appVM.user)
                case .historyOnly:
                    try FriendCacheManager.resetAllAccountsHistory()
                }
                
                await MainActor.run {
                    alertTitle = "재설정 완료"
                    alertMessage = "\(type.title) 작업을 완료했습니다."
                    showingAlert = true
                    
                    refreshDataStatus()
                }
            } catch {
                await MainActor.run {
                    alertTitle = "재설정 실패"
                    alertMessage = "재설정 중 오류가 발생했습니다: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct BackupActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            iconView
            textContent
            Spacer()
            chevronView
        }
        .padding(.vertical, 8)
    }
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 40, height: 40)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
            }
        }
    }
    
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var chevronView: some View {
        Group {
            if !isLoading {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview Sheets

struct PreviewSheet: View {
    let previewResult: FriendCacheManager.PreviewResult
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    previewIcon
                    previewTitle
                }
                changesSummary
                Spacer()
                actionButtons
            }
            .padding(24)
            .navigationBarHidden(true)
        }
    }
    
    private var previewIcon: some View {
        Image(systemName: "clock.arrow.circlepath")
            .font(.system(size: 60))
            .foregroundStyle(.blue.gradient)
    }
    
    private var previewTitle: some View {
        Text("친구 데이터 복원")
            .font(.title2)
            .fontWeight(.bold)
    }
    
    private var changesSummary: some View {
        VStack(spacing: 16) {
            previewCards
            Divider()
            changesDetail
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var previewCards: some View {
        VStack(spacing: 16) {
            PreviewCard(
                title: "백업 파일",
                value: "\(previewResult.backupFriendsCount)명",
                icon: "doc.circle.fill",
                color: .blue
            )
            
            PreviewCard(
                title: "현재 친구",
                value: "\(previewResult.currentFriendsCount)명",
                icon: "person.2.circle.fill",
                color: .green
            )
        }
    }
    
    private var changesDetail: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.fill.badge.plus")
                    .foregroundColor(.blue)
                Text("새로 추가될 친구")
                Spacer()
                Text("\(previewResult.addedCount)명")
                    .fontWeight(.semibold)
            }
            
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.orange)
                Text("업데이트될 친구")
                Spacer()
                Text("\(previewResult.updatedCount)명")
                    .fontWeight(.semibold)
            }
            
            if previewResult.historyAddedCount > 0 {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.green)
                    Text("새로 추가될 기록")
                    Spacer()
                    Text("\(previewResult.historyAddedCount)개")
                        .fontWeight(.semibold)
                }
            }
        }
        .font(.subheadline)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("가져오기", systemImage: "square.and.arrow.down", action: onConfirm)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            
            Button("취소", action: onCancel)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(10)
        }
    }
}

struct PreviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            cardIcon
            cardContent
            Spacer()
        }
    }
    
    private var cardIcon: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 44, height: 44)
            
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SafeShareSheet: UIViewControllerRepresentable {
    let fileURL: URL
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("❌ File does not exist at path: \(fileURL.path)")
            let emptyController = UIActivityViewController(activityItems: [], applicationActivities: nil)
            DispatchQueue.main.async {
                dismiss()
            }
            return emptyController
        }
        
        print("✅ Sharing file: \(fileURL.lastPathComponent)")
        print("📁 File path: \(fileURL.path)")
        print("📏 File size: \(FileManager.default.fileSize(at: fileURL) ?? "Unknown")")
        
        let activityController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        activityController.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
            if let error = activityError {
                print("❌ Share error: \(error.localizedDescription)")
            } else if completed {
                print("✅ Share completed with activity: \(activityType?.rawValue ?? "Unknown")")
            } else {
                print("ℹ️ Share cancelled")
            }
        }
        
        return activityController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ResetSelectionSheet: View {
    @Binding var resetType: FriendBackupView.ResetType
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(FriendBackupView.ResetType.allCases, id: \.self) { type in
                    Button {
                        resetType = type
                        onConfirm()
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(type.color.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: type.icon)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(type.color)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(type.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("재설정 옵션 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        onCancel()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

extension FileManager {
    func fileSize(at url: URL) -> String? {
        do {
            let attributes = try attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? Int64 {
                return ByteCountFormatter().string(fromByteCount: size)
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        return nil
    }
}

#Preview {
    FriendBackupView()
}
