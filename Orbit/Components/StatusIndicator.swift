//
//  StatusIndicator.swift
//  Orbit
//
//  Created by xili on 2024/09/19.
//

import SwiftUI

struct StatusIndicator<S>: View where S: ShapeStyle {
    private let content: S
    private let isCutOut: Bool
    private let size: CGSize?
    private let outerSize: CGSize

    init(_ content: S, outerSize: CGSize, isCutOut: Bool = false) {
        self.content = content
        self.outerSize = outerSize
        self.isCutOut = isCutOut
        self.size = nil
    }

    init(_ content: S, size: CGSize, isCutOut: Bool = false) {
        self.content = content
        self.outerSize = .zero
        self.isCutOut = isCutOut
        self.size = size
    }

    private var frameSize: CGSize {
        size ?? outerSize * 0.3
    }

    private var cutoutSize: CGSize {
        frameSize * 0.5
    }

    private var offset: CGSize {
        outerSize * 0.36
    }

    var body: some View {
        let indicatorShape = Circle()
        let lineWidth = frameSize.width / 4

        Group {
            if isCutOut {
                indicatorShape
                    .strokeBorder(content, lineWidth: lineWidth)
            } else {
                indicatorShape
                    .fill(content)
            }
        }
        .frame(size: frameSize)
        .offset(x: offset.width, y: offset.height)
    }
}

#Preview {
    StatusIndicator(
        .blue,
        outerSize: CGSize(width: 120, height: 120)
    )
}
