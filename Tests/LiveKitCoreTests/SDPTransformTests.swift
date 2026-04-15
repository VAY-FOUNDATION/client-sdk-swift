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

import XCTest
@testable import LiveKit
#if canImport(LiveKitTestSupport)
import LiveKitTestSupport
#endif

/// Unit tests for the public SDP-transform delegate API.
/// Verifies the passthrough contract, delegate invocation parameters,
/// and idempotency of a canonical Opus `packetlossperc` transform.
final class SDPTransformTests: LKTestCase {

    // MARK: - Fixtures

    private let sampleOfferSDP = """
    v=0
    o=- 0 0 IN IP4 127.0.0.1
    s=-
    t=0 0
    m=audio 9 UDP/TLS/RTP/SAVPF 111
    a=rtpmap:111 opus/48000/2
    a=fmtp:111 minptime=10;useinbandfec=1
    a=ptime:20
    """

    // MARK: - Passthrough default

    func testDefaultImpl_isPassthrough() async {
        final class Noop: SDPTransformDelegate {}
        let sut = Noop()
        let out = await sut.room(
            Room(),
            willSetSessionDescription: sampleOfferSDP,
            direction: .local,
            target: .publisher
        )
        XCTAssertEqual(out, sampleOfferSDP)
    }

    // MARK: - packetlossperc transform

    func testOpusPacketLossPercTransform_addsParameter() async {
        final class PacketLossHint: SDPTransformDelegate {
            let percent: Int
            init(percent: Int) { self.percent = percent }

            func room(
                _: Room,
                willSetSessionDescription sdp: String,
                direction: SDPDirection,
                target: TransportTarget
            ) async -> String {
                guard direction == .local, target == .publisher else { return sdp }
                guard !sdp.contains("packetlossperc=") else { return sdp } // idempotent
                return sdp.replacingOccurrences(
                    of: "useinbandfec=1",
                    with: "useinbandfec=1;packetlossperc=\(percent)"
                )
            }
        }
        let sut = PacketLossHint(percent: 20)
        let out = await sut.room(
            Room(),
            willSetSessionDescription: sampleOfferSDP,
            direction: .local,
            target: .publisher
        )
        XCTAssertTrue(out.contains("packetlossperc=20"))
        XCTAssertTrue(out.contains("useinbandfec=1;packetlossperc=20"))
    }

    func testOpusPacketLossPercTransform_idempotent() async {
        final class PacketLossHint: SDPTransformDelegate {
            let percent: Int
            init(percent: Int) { self.percent = percent }

            func room(
                _: Room,
                willSetSessionDescription sdp: String,
                direction: SDPDirection,
                target: TransportTarget
            ) async -> String {
                guard direction == .local, target == .publisher else { return sdp }
                guard !sdp.contains("packetlossperc=") else { return sdp }
                return sdp.replacingOccurrences(
                    of: "useinbandfec=1",
                    with: "useinbandfec=1;packetlossperc=\(percent)"
                )
            }
        }
        let sut = PacketLossHint(percent: 20)
        let once = await sut.room(Room(), willSetSessionDescription: sampleOfferSDP, direction: .local, target: .publisher)
        let twice = await sut.room(Room(), willSetSessionDescription: once, direction: .local, target: .publisher)
        XCTAssertEqual(once, twice, "Transform must be idempotent")
    }

    // MARK: - Direction / target gating

    func testTransform_ignoresRemoteDirection() async {
        final class PublisherOnly: SDPTransformDelegate {
            func room(
                _: Room,
                willSetSessionDescription sdp: String,
                direction: SDPDirection,
                target: TransportTarget
            ) async -> String {
                guard direction == .local else { return sdp }
                return sdp + "\na=custom:x"
            }
        }
        let sut = PublisherOnly()
        let out = await sut.room(
            Room(),
            willSetSessionDescription: sampleOfferSDP,
            direction: .remote,
            target: .publisher
        )
        XCTAssertEqual(out, sampleOfferSDP, "Remote direction must be passed through unchanged")
    }

    func testTransform_ignoresSubscriberTarget() async {
        final class PublisherOnly: SDPTransformDelegate {
            func room(
                _: Room,
                willSetSessionDescription sdp: String,
                direction: SDPDirection,
                target: TransportTarget
            ) async -> String {
                guard target == .publisher else { return sdp }
                return sdp + "\na=custom:x"
            }
        }
        let sut = PublisherOnly()
        let out = await sut.room(
            Room(),
            willSetSessionDescription: sampleOfferSDP,
            direction: .local,
            target: .subscriber
        )
        XCTAssertEqual(out, sampleOfferSDP, "Subscriber target must be passed through unchanged")
    }

    // MARK: - Room wiring

    func testRoom_sdpTransformDelegateAssignment() {
        final class NoOp: SDPTransformDelegate {}
        let delegate = NoOp()
        let room = Room()
        XCTAssertNil(room.sdpTransformDelegate)
        room.sdpTransformDelegate = delegate
        XCTAssertNotNil(room.sdpTransformDelegate)
        XCTAssertTrue(room.sdpTransformDelegate === delegate)
        room.sdpTransformDelegate = nil
        XCTAssertNil(room.sdpTransformDelegate)
    }

    // MARK: - Enum sanity

    func testEnums_rawValuesStable() {
        XCTAssertEqual(SDPDirection.local.rawValue, "local")
        XCTAssertEqual(SDPDirection.remote.rawValue, "remote")
        XCTAssertEqual(TransportTarget.publisher.rawValue, "publisher")
        XCTAssertEqual(TransportTarget.subscriber.rawValue, "subscriber")
    }
}
