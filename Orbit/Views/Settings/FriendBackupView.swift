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
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingFilePicker = false
    @State private var showingPreview = false
    @State private var showingConfirmation = false
    @State private var showingCompleteBackupPicker = false
    @State private var showingCompleteBackupConfirmation = false
    @State private var showingShareSheet = false
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var previewResult: FriendCacheManager.PreviewResult?
    @State private var completeBackupResult: FriendCacheManager.CompleteBackupResult?
    @State private var selectedBackupURL: URL?
    @State private var backupType: BackupType = .friendsOnly
    @State private var exportedFileURL: URL?
    @State private var dataStatus = FriendCacheManager.getDataStatus()
    
    enum BackupType {
        case friendsOnly
        case complete
    }
    
    var body: some View {
        List {
            headerSection
            dataStatusSection
            dataManagementSection
            importantNoticeSection
        }
        .navigationTitle("친구 데이터 관리")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshDataStatus()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
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
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedBackupURL = url
                    generatePreview(for: url)
                }
            case .failure(let error):
                alertMessage = "파일 선택 오류: \(error.localizedDescription)"
                showingAlert = true
            }
        }
        .alert("확인", isPresented: $showingConfirmation) {
            Button("가져오기") {
                if let url = selectedBackupURL {
                    importFriendData(from: url)
                }
            }
            Button("취소", role: .cancel) {
                selectedBackupURL = nil
            }
        } message: {
            Text("변경사항이 없습니다. 그래도 가져오시겠습니까?")
        }
        .alert("알림", isPresented: $showingAlert) {
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
            
            Text("친구 목록과 기록을 안전하게 백업하고 복원할 수 있습니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var dataStatusSection: some View {
        Section {
            dataStatusContent
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
    
    private var footerContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .frame(width: 16, height: 16)
                Text("백업에는 친구 목록과 친구 기록이 모두 포함됩니다.")
            }
            
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.merge")
                    .foregroundColor(.green)
                    .frame(width: 16, height: 16)
                Text("백업을 복원하면 기존 데이터와 자동으로 병합됩니다.")
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let exportURL = FriendCacheManager.exportCompleteBackup() {
                DispatchQueue.main.async {
                    isExporting = false
                    exportedFileURL = exportURL
                    showingShareSheet = true
                }
            } else {
                DispatchQueue.main.async {
                    isExporting = false
                    alertMessage = "백업 생성에 실패했습니다. 친구 데이터가 없거나 오류가 발생했습니다."
                    showingAlert = true
                }
            }
        }
    }
    
    private func generatePreview(for url: URL) {
        isImporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let success = url.startAccessingSecurityScopedResource()
            defer {
                if success {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                let preview = try FriendCacheManager.generatePreview(from: url)
                
                DispatchQueue.main.async {
                    isImporting = false
                    previewResult = preview
                    
                    if preview.totalChanges == 0 {
                        showingConfirmation = true
                    } else {
                        showingPreview = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isImporting = false
                    alertMessage = "백업 파일을 읽을 수 없습니다: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func importFriendData(from url: URL) {
        isImporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let success = url.startAccessingSecurityScopedResource()
            defer {
                if success {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                print("🔄 Starting complete backup import...")
                let result = try FriendCacheManager.importCompleteBackup(from: url)
                
                DispatchQueue.main.async {
                    isImporting = false
                    
                    let friendMessage = "친구 \(result.friendMergeResult.addedCount)명 추가, \(result.friendMergeResult.updatedCount)명 업데이트"
                    let historyMessage = "기록 \(result.historyImported)개 추가"
                    
                    alertMessage = "복원 완료!\n\(friendMessage)\n\(historyMessage)"
                    showingAlert = true
                    
                    selectedBackupURL = nil
                    previewResult = nil
                    refreshDataStatus()
                }
            } catch {
                DispatchQueue.main.async {
                    isImporting = false
                    alertMessage = "복원 실패: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func refreshDataStatus() {
        dataStatus = FriendCacheManager.getDataStatus()
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

#Preview {
    FriendBackupView()
}
