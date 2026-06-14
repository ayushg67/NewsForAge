import SwiftUI
import SafariServices

/// In-app browser using SFSafariViewController for reading the full article.
struct SafariWebView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        return SFSafariViewController(url: url, configuration: config)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
