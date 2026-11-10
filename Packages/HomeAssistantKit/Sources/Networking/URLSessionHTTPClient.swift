import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: AuthTokenProvider?

    public init(baseURL: URL, session: URLSession = .shared, tokenProvider: AuthTokenProvider? = nil) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
    }

    public func send(_ endpoint: Endpoint) async throws -> Data {
        let request = try await authorizedRequest(for: endpoint)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw APIError.offline
        }
        try Self.validate(response, body: data)
        return data
    }

    public func eventStream(_ endpoint: Endpoint) -> AsyncThrowingStream<ServerSentEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = try await self.authorizedRequest(for: endpoint)
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    let (bytes, response) = try await self.session.bytes(for: request)
                    try Self.validate(response, body: nil)

                    // `AsyncBytes.lines` drops empty lines, but an empty line is what
                    // terminates an SSE event — so lines are split manually here.
                    var parser = ServerSentEventParser()
                    var lineBuffer: [UInt8] = []
                    for try await byte in bytes {
                        if byte == UInt8(ascii: "\n") {
                            let line = String(decoding: lineBuffer, as: UTF8.self)
                            lineBuffer.removeAll(keepingCapacity: true)
                            if let event = parser.consume(line: line) {
                                continuation.yield(event)
                            }
                        } else {
                            lineBuffer.append(byte)
                        }
                    }
                    if !lineBuffer.isEmpty,
                       let event = parser.consume(line: String(decoding: lineBuffer, as: UTF8.self)) {
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch let error as URLError where error.code == .cancelled {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func authorizedRequest(for endpoint: Endpoint) async throws -> URLRequest {
        var request = try endpoint.urlRequest(baseURL: baseURL)
        if let token = try await tokenProvider?.accessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private static func validate(_ response: URLResponse, body: Data?) throws {
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        switch http.statusCode {
        case 200..<300: return
        case 401: throw APIError.unauthorized
        default:
            let message = body.flatMap { String(data: $0, encoding: .utf8) }
            throw APIError.server(statusCode: http.statusCode, message: message)
        }
    }
}
