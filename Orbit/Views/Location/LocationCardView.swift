//
//  LocationCardView.swift
//  Orbit
//
//  Created by makinosp on 2024/06/15.
//

import NukeUI
import SwiftUI
import VRCKit

struct LocationCardView: View {
    @Environment(AppViewModel.self) var appVM
    @Binding var selected: InstanceLocation?
    @State private var instance: Instance?
    @State private var isRequesting = true
    @State private var isFailure = false
    let location: FriendsLocation

    var body: some View {
        locationCardContent(instance: instance ?? PreviewData.instance)
            .redacted(reason: instance == nil ? .placeholder : [])
            .task {
                if case let .id(id) = location.location {
                    do {
                        defer { withAnimation { isRequesting = false } }
                        let service = appVM.services.instanceService
                        instance = try await service.fetchInstance(location: id)
                    } catch {
                        print(error)
                        isFailure = true
                    }
                }
            }
    }

    private func locationCardContent(instance: Instance) -> some View {
        Button {
            if !isRequesting {
                selected = tag(instance)
            }
        } label: {
            VStack(spacing: 0) {
                // 상단 - 월드 이미지와 정보
                HStack(spacing: 12) {
                    // 월드 이미지
                    ZStack {
                        GradientOverlayImageView(
                            imageUrl: instance.world.imageUrl(.x512),
                            thumbnailImageUrl: instance.world.imageUrl(.x256),
                            size: CGSize(width: 80, height: 65)
                        )
                        .frame(width: 80, height: 65)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        // 플랫폼 아이콘 (우측 상단 오버레이)
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: instance.world.platform == .windows ? "pc" : "questionmark")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.6))
                                    )
                            }
                            Spacer()
                        }
                        .frame(width: 80, height: 65)
                        
                        if isRequesting {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.regularMaterial)
                                .frame(width: 80, height: 65)
                            
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    // 월드 정보
                    VStack(alignment: .leading, spacing: 4) {
                        // 월드 이름
                        Text(instance.world.name)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        // 월드 상세 정보 (ID, 유형)
                        Text(InstanceUtil.getInstanceWithInstanceType(instance))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                            .lineLimit(1)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(personAmount(instance))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // 화살표
                    if !isRequesting {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // 하단 - 친구 목록 (구분선 포함)
                if !location.friends.isEmpty {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(location.friends.count)명의 친구")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        HorizontalProfileImages(location.friends)
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
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.cyan.opacity(selected?.id == tag(instance).id ? 0.3 : 0.1),
                                        Color.blue.opacity(selected?.id == tag(instance).id ? 0.2 : 0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: selected?.id == tag(instance).id ? 2 : 1
                            )
                    }
                    .shadow(
                        color: selected?.id == tag(instance).id ? Color.cyan.opacity(0.2) : Color.black.opacity(0.05),
                        radius: selected?.id == tag(instance).id ? 8 : 4,
                        x: 0,
                        y: selected?.id == tag(instance).id ? 4 : 2
                    )
            }
        }
        .buttonStyle(.plain)
        .selectionDisabled(isRequesting)
        .tag(tag(instance))
        .animation(.easeInOut(duration: 0.2), value: selected?.id == tag(instance).id)
    }

    private func tag(_ instance: Instance) -> InstanceLocation {
        InstanceLocation(location: location, instance: instance)
    }

    private func personAmount(_ instance: Instance) -> String {
        [location.friends.count, instance.userCount, instance.capacity]
            .map { $0.description }
            .joined(separator: " / ")
    }
}
