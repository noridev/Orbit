//
//  NavigationLabel.swift
//  Orbit
//
//  Created by makinosp on 2024/09/22.
//

import MemberwiseInit
import SwiftUI

@MainActor @MemberwiseInit
struct NavigationLabel<Label> where Label: View {
    @Init(.internal, default: { EmptyView() }, escaping: true) private let label: () -> Label

    @ViewBuilder
    func content() -> some View {
        if UIDevice.current.userInterfaceIdiom != .pad {
            IconSet.forward.icon
                .foregroundStyle(Color(.tertiaryLabel))
                .imageScale(.small)
                .unredacted()
        }
    }
}

extension NavigationLabel: View {
    var body: some View {
        HStack {
            label()
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
    }
}

extension NavigationLabel where Label == EmptyView {
    var body: some View {
        content()
    }
}
