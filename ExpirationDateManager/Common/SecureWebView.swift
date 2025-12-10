import WebKit
import SwiftUI

// MARK: - SecureWebView
struct SecureWebView: UIViewControllerRepresentable {
    let url: URL
    @Binding var loading: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let cfg = WKWebViewConfiguration()
        let web = WKWebView(frame: .zero, configuration: cfg)
        web.navigationDelegate = context.coordinator
        web.isInspectable = true
        let vc = UIViewController()
        vc.view = web
        loading = true
        print("🌐 Загружаем WebView → \(url)")
        web.load(URLRequest(url: url))
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(loading: $loading) }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var loading: Bool
        init(loading: Binding<Bool>) { _loading = loading }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ WebView: страница успешно загружена")
            loading = false
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ Ошибка при загрузке страницы: \(error.localizedDescription)")
            loading = false
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ Ошибка при предварительной загрузке: \(error.localizedDescription)")
            loading = false
        }
    }
}
