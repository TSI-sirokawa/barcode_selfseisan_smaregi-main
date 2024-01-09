//
//  Shape.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/07/08.
//

import SwiftUI

extension Shape {
    /// fills and strokes a shape
    public func fill<S:ShapeStyle>(
        _ fillContent: S,
        strokeContent: S,
        strokeStyle: StrokeStyle
    ) -> some View {
        ZStack {
            self.stroke(strokeContent, style: strokeStyle)
            self.fill(fillContent)
        }
    }
}
