//
//  HorizontalProfileImages.swift
//  Orbit
//
//  Created by makinosp on 2024/10/27.
//

import SwiftUI
import MemberwiseInit
import VRCKit

@MemberwiseInit
struct HorizontalProfileImages<T>: View where T: ProfileElementRepresentable {
    @Init(.internal, label: "_") private let profiles: [T]
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: -8) {
                ForEach(profiles) { profile in
                    UserIcon(
                        user: profile,
                        size: Constants.IconSize.thumbnail,
                        showStatusIndicator: false,
                        showTrustRankBorder: false
                    )
                }
            }
        }
    }
}
