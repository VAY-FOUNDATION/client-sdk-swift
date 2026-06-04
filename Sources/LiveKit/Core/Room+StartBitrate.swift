import Foundation

public extension Room {
    /// Seed the publisher peer connection's congestion-control estimate so video
    /// opens at a usable resolution. Call AFTER the publisher transport connects.
    /// No-op if there is no publisher yet. Only the start estimate is seeded.
    func setPublisherStartBitrate(currentBps: Int) async {
        guard let publisher = _state.read({ $0.publisher }) else { return }
        await publisher.setStartBitrate(currentBps: currentBps)
    }
}
