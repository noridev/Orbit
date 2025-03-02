import SwiftUI
import SafariServices

// SafariViewController를 SwiftUI에서 사용하기 위한 Wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // SafariViewController 업데이트 필요할 때 처리
    }
}
