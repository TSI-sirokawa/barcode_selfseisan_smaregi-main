//
//  ActivityIndicator.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/09/04.
//

import SwiftUI

/// インジケータ表示
struct ActivityIndicator: UIViewRepresentable {
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: .large)
    }
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        uiView.startAnimating()
    }
}
