import Foundation

struct Recording: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let creationDate: Date
    
    var name: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return "録音 \(formatter.string(from: creationDate))"
    }
    
    var duration: TimeInterval {
        return 0
    }
}
