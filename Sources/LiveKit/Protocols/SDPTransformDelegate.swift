/*
 * Copyright 2026 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

/// Optional delegate that lets the app inspect and modify the raw SDP
/// before LiveKit applies it to the underlying PeerConnection.
///
/// Intended use: apps targeting unusual networks (2G / satellite / flaky
/// Wi-Fi) that need to edit codec parameters — Opus `packetlossperc`,
/// `ptime`, FlexFEC `a=rtpmap` — without waiting for a dedicated SDK
/// field per parameter.
///
/// The delegate receives the SDP as a `String` and returns a (possibly
/// modified) `String`. Returning the input unchanged is a no-op.
///
/// ## Threading
/// Invoked from the Transport actor's context, off the main actor.
/// Implementations should be fast (< 10 ms) and allocation-light.
///
/// ## Failure mode
/// If the transform returns malformed SDP, `setLocalDescription` /
/// `setRemoteDescription` will reject it and throw. Apps are expected to
/// fail open on parse errors and return the input unchanged rather than
/// returning a partial/broken SDP.
///
/// ## Example
/// ```swift
/// final class OpusHintTransform: SDPTransformDelegate {
///     func room(
///         _ room: Room,
///         willSetSessionDescription sdp: String,
///         direction: SDPDirection,
///         target: TransportTarget
///     ) async -> String {
///         guard direction == .local, target == .publisher else { return sdp }
///         return sdp.replacingOccurrences(
///             of: "useinbandfec=1",
///             with: "useinbandfec=1;packetlossperc=20"
///         )
///     }
/// }
/// ```
public protocol SDPTransformDelegate: AnyObject, Sendable {
    /// Called right before a session description is applied. Return the
    /// modified SDP or pass `sdp` through unchanged.
    ///
    /// - Parameters:
    ///   - room: The `Room` that owns the Transport.
    ///   - sdp: The raw SDP text about to be applied.
    ///   - direction: `.local` when we're setting our own offer/answer,
    ///     `.remote` when we're accepting the SFU's.
    ///   - target: `.publisher` or `.subscriber`.
    /// - Returns: The SDP text to use.
    func room(
        _ room: Room,
        willSetSessionDescription sdp: String,
        direction: SDPDirection,
        target: TransportTarget
    ) async -> String
}

public extension SDPTransformDelegate {
    /// Default implementation: no-op passthrough.
    func room(
        _ room: Room,
        willSetSessionDescription sdp: String,
        direction: SDPDirection,
        target: TransportTarget
    ) async -> String {
        sdp
    }
}
