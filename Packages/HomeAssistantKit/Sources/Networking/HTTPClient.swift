import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET", post = "POST", put = "PUT", patch = "PATCH", delete = "DELETE"
}

/// Describes one backend call. Built by feature-specific API clients (Phase 4).
public struct Endpoint: Sendable {
    public var path: String
    public var method: HTTPMethod
    public var queryItems: [URLQueryItem]
    public var headers: [String: String]
    public var body: Data?

    public init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }

    public static func json<Body: Encodable>(
        _ path: String,
        method: HTTPMethod = .post,
        body: Body,
        encoder: JSONEncoder = .api
    ) throws -> Endpoint {
        Endpoint(
            path: path,
            method: method,
            headers: ["Content-Type": "application/json"],
            body: try encoder.encode(body)
        )
    }

    func urlRequest(baseURL: URL) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else { throw APIError.invalidURL }
        if !queryItems.isEmpty { components.queryItems = queryItems }
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        for (field, value) in headers { request.setValue(value, forHTTPHeaderField: field) }
        return request
    }
}

public enum APIError: Error, Equatable, Sendable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case server(statusCode: Int, message: String?)
    case decoding(String)
    case offline
}

/// Supplies the user's session token. Never an LLM API key — those stay on the backend.
public protocol AuthTokenProvider: Sendable {
    func accessToken() async throws -> String?
}

public protocol HTTPClient: Sendable {
    func send(_ endpoint: Endpoint) async throws -> Data
    func eventStream(_ endpoint: Endpoint) -> AsyncThrowingStream<ServerSentEvent, Error>
}

public extension HTTPClient {
    func send<Response: Decodable>(
        _ endpoint: Endpoint,
        as type: Response.Type,
        decoder: JSONDecoder = .api
    ) async throws -> Response {
        let data = try await send(endpoint)
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }
}

public extension JSONEncoder {
    static var api: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

public extension JSONDecoder {
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
