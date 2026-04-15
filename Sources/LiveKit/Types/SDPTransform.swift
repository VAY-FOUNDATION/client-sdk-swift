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

/// Direction of an SDP being processed — is this the description produced
/// by the local peer (offer or answer about to be sent to the remote side)
/// or received from the remote peer (about to be applied locally).
public enum SDPDirection: String, Sendable, Equatable {
    case local
    case remote
}

/// Which underlying transport the SDP belongs to.
public enum TransportTarget: String, Sendable, Equatable {
    case publisher
    case subscriber
}
