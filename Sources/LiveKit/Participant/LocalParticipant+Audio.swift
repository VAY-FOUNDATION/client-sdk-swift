/*
 * VAY extension — mid-call audio bitrate actuation.
 * See https://github.com/vay-foundation/vay/tree/main/docs/upstream/
 */

import Foundation

internal import LiveKitWebRTC

public extension LocalParticipant {
    /// Changes the audio encoding on the currently-published audio track
    /// without requiring reconnection or SDP renegotiation.
    ///
    /// Uses RTCRtpSender.setParameters() under the hood (wrapped as a
    /// property setter in LiveKit's LKRTCRtpSender). The underlying Opus
    /// encoder reacts to the new `maxBitrate` within 1–2 seconds (next
    /// encoder reconfiguration tick). No packet loss at the transition.
    ///
    /// - Parameter encoding: New audio encoding. Only `maxBitrate` is
    ///   honored — this method does not re-publish the track.
    /// - Throws: `LiveKitError(.invalidState)` if no local audio track is
    ///   currently published or if the sender has no encoding parameters.
    ///
    /// Idempotent: no-op if the sender's current `maxBitrate` already
    /// matches `encoding.maxBitrate`.
    func setAudioEncoding(_ encoding: AudioEncoding) async throws {
        guard let publication = audioTracks.first(where: { $0.track is LocalAudioTrack }),
              let track = publication.track as? LocalAudioTrack,
              let sender = track.rtpSender
        else {
            throw LiveKitError(.invalidState,
                               message: "setAudioEncoding: no published LocalAudioTrack")
        }

        let params = sender.parameters
        guard !params.encodings.isEmpty else {
            throw LiveKitError(.invalidState,
                               message: "setAudioEncoding: sender has no encoding parameters")
        }

        // Idempotence: skip if the bitrate already matches.
        let currentBitrate = params.encodings[0].maxBitrateBps?.intValue ?? 0
        guard currentBitrate != encoding.maxBitrate else { return }

        params.encodings[0].maxBitrateBps = NSNumber(value: encoding.maxBitrate)

        // LKRTCRtpSender exposes setParameters() as a property setter.
        // Matches the convention used in LocalTrackPublication.swift:211
        // and LocalParticipant.swift:677.
        sender.parameters = params
    }
}
