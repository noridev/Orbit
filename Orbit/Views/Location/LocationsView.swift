//
//  LocationsView.swift
//  Orbit
//
//  Created by makinosp on 2024/03/16.
//

import SwiftUI
import VRCKit

struct LocationsView: View {
    @Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedInstance: InstanceLocation?
    @State private var isSelectedPrivate = false
    @State private var selection: SegmentIdSelection?

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } content: {
            ZStack {
                // 그라데이션 배경
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.cyan.opacity(0.08),
                        Color.blue.opacity(0.05),
                        Color.clear
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if friendVM.friendsLocations.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(friendVM.friendsLocations) { location in
                                LocationCardView(selected: $selectedInstance, location: location)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.large)
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Color(UIColor { $0.userInterfaceStyle == .dark ? .white : .black }))
        .refreshable {
            await friendVM.fetchAllFriends { error in
                appVM.handleError(error)
            }
        }
    }

    private var sidebar: some View {
        ZStack {
            // 그라데이션 배경
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.08),
                    Color.green.opacity(0.05),
                    Color.clear
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    if friendVM.isContentUnavailable {
                        emptyStateView
                    } else {
                        friendLocationsCard
                        if !friendVM.isFetchingAllFriends && !friendVM.friendsInPrivate.isEmpty {
                            privateInstanceCard
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .navigationTitle("Social")
        .setColumn(appVM.screenSize)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 80)
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.green.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: IconSet.friends.systemName)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text("친구 위치 없음")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("온라인 친구가 없거나 모든 친구가 비공개 상태입니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var friendLocationsCard: some View {
        VStack(spacing: 16) {
            // 카드 헤더
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    Text("친구 위치")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if friendVM.isFetchingAllFriends {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("\(friendVM.visibleFriendsLocations.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            // 친구 위치 목록
            if friendVM.isFetchingAllFriends {
                VStack(spacing: 12) {
                    ForEach(0...3, id: \.self) { _ in
                        LocationCardView(
                            selected: .constant(nil),
                            location: PreviewData.friendsLocation
                        )
                        .redacted(reason: .placeholder)
                    }
                }
            } else if friendVM.visibleFriendsLocations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    
                    Text("표시할 위치가 없습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 12) {
                    ForEach(friendVM.visibleFriendsLocations) { location in
                        LocationCardView(
                            selected: $selectedInstance,
                            location: location
                        )
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    }
    
    private var privateInstanceCard: some View {
        VStack(spacing: 16) {
            // 카드 헤더
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "lock.circle.fill")
                        .foregroundColor(.purple)
                        .font(.title2)
                    
                    Text("비공개 인스턴스")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("(\(friendVM.friendsInPrivate.count))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            // 비공개 인스턴스 카드
            Button {
                selectedInstance = InstanceLocation(friends: friendVM.friendsInPrivate)
            } label: {
                VStack(spacing: 0) {
                    // 상단 - 기본 정보
                    HStack(spacing: 12) {
                        // 비공개 아이콘
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 60)
                            
                            VStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                
                                Text("Private")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // 정보
                        VStack(alignment: .leading, spacing: 6) {
                            Text("비공개 인스턴스")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Private Instance")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(Capsule())
                            
                            Spacer()
                        }
                        
                        Spacer()
                        
                        // 인원수와 화살표
                        VStack(spacing: 8) {
                            VStack(spacing: 2) {
                                Image(systemName: "person.2.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(friendVM.friendsInPrivate.count)")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    
                    // 하단 - 친구 정보
                    if !friendVM.friendsInPrivate.isEmpty {
                        Divider()
                            .padding(.horizontal, 16)
                        
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(friendVM.friendsInPrivate.count)명의 친구")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            HorizontalProfileImages(friendVM.friendsInPrivate)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .padding(.top, 8)
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    Color.purple.opacity(0.5),
                                    lineWidth: 2
                                )
                        }
                        .shadow(
                            color: .black.opacity(0.08),
                            radius: 6,
                            x: 0,
                            y: 3
                        )
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    }

    private var content: some View {
        ZStack {
            // 그라데이션 배경
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.08),
                    Color.blue.opacity(0.05),
                    Color.clear
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Group {
                if let location = selectedInstance?.location,
                   let instance = selectedInstance?.instance {
                    LocationDetailView(location: location, instance: instance)
                } else if let instance = selectedInstance, instance.location.location == .private {
                    PrivateLocationView($selection, friends: instance.location.friends)
                } else {
                    emptySelectionView
                }
            }
        }
        .setColumn(appVM.screenSize)
    }
    
    private var emptySelectionView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green.opacity(0.2), Color.blue.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: IconSet.location.systemName)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                Text("위치를 선택하세요")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("왼쪽에서 친구의 위치를 선택하여 상세 정보를 확인하세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    private var detail: some View {
        ZStack {
            // 그라데이션 배경
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.orange.opacity(0.08),
                    Color.pink.opacity(0.05),
                    Color.clear
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            NavigationStack {
                Group {
                    if let selection = selection {
                        Group {
                            switch selection.segment {
                            case .friends:
                                UserDetailPresentationView(selected: selection.selected)
                                    .id(selection.id)
                            case .world:
                                WorldPresentationView(id: selection.selected.id)
                                    .id(selection.id)
                            }
                        }
                    } else {
                        emptyDetailView
                    }
                }
                .setColumn(appVM.screenSize)
            }
        }
    }
    
    private var emptyDetailView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange.opacity(0.2), Color.pink.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: IconSet.info.systemName)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 8) {
                Text("친구 또는 월드를 선택하세요")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("위치에서 친구나 월드를 선택하여 자세한 정보를 확인하세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

extension Location {
    var isVisible: Bool {
        switch self {
        case .id: true
        default: false
        }
    }
}

private extension View {
    func setColumn(_ screenSize: CGSize) -> some View {
        navigationSplitViewColumnWidth(
            min: screenSize.width * 1 / 3,
            ideal: screenSize.width * 1 / 3,
            max: screenSize.width / 2
        )
    }
}

#Preview {
    PreviewContainer {
        LocationsView()
    }
}
