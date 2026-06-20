import Foundation

struct RecordingSession: Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    var status: Status
    var resultImageFilename: String?

    enum Status: String, Codable {
        case recording
        case processing
        case completed
        case failed
    }
}
