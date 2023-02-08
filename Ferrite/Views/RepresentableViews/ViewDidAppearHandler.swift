//
//  ViewDidAppearHandler.swift
//  Ferrite
//
//  Created by Brian Dashore on 2/8/23.
//
//  UIKit onAppear hook to fix onAppear behavior in iOS 14
//

import SwiftUI

struct ViewDidAppearHandler: UIViewControllerRepresentable {
    let callback: () -> Void

    class Coordinator: UIViewController {
        let callback: () -> Void

        init(callback: @escaping () -> Void) {
            self.callback = callback
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            callback()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(callback: callback)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        context.coordinator
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
