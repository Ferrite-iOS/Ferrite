//
//  WebView.swift
//  Ferrite
//
//  Created by Brian Dashore on 7/17/22.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    @AppStorage("Behavior.UseEphemeralAuth") var useEphemeralAuth: Bool = true
    var url: URL

    func makeUIView(context: Context) -> WKWebView {
        // Make the WebView ephemeral depending on the ephemeral auth setting
        let config = WKWebViewConfiguration()

        config.websiteDataStore = useEphemeralAuth ? .nonPersistent() : .default()

        let webView = WKWebView(frame: .zero, configuration: config)
        let _ = webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.configuration.websiteDataStore = useEphemeralAuth ? .nonPersistent() : .default()
    }
}

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView(url: URL(string: "https://google.com")!)
    }
}
