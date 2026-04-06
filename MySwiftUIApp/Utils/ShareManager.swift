import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

@MainActor
class ShareManager: ObservableObject {
    @Published var isShowingShareSheet = false
    @Published var shareItems: [Any] = []
    
    func shareRecording(_ recording: Recording) {
        shareItems = [recording.url]
        isShowingShareSheet = true
    }
}
