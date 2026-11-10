import Foundation

public struct ServerSentEvent: Equatable, Sendable {
    public var event: String
    public var data: String
    public var id: String?

    public init(event: String = "message", data: String, id: String? = nil) {
        self.event = event
        self.data = data
        self.id = id
    }
}

/// Incremental parser for the `text/event-stream` format (WHATWG HTML §9.2).
/// Feed it one line at a time (without the trailing `\n`); it returns an event
/// whenever a blank line completes one.
public struct ServerSentEventParser: Sendable {
    private var eventType = ""
    private var dataLines: [String] = []
    private var lastEventID: String?

    public init() {}

    public mutating func consume(line rawLine: String) -> ServerSentEvent? {
        let line = rawLine.hasSuffix("\r") ? String(rawLine.dropLast()) : rawLine

        if line.isEmpty { return dispatch() }
        if line.hasPrefix(":") { return nil } // comment / keep-alive

        let field: Substring
        var value: Substring
        if let colon = line.firstIndex(of: ":") {
            field = line[..<colon]
            value = line[line.index(after: colon)...]
            if value.first == " " { value = value.dropFirst() }
        } else {
            field = Substring(line)
            value = ""
        }

        switch field {
        case "event": eventType = String(value)
        case "data": dataLines.append(String(value))
        case "id" where !value.contains("\0"): lastEventID = String(value)
        default: break // `retry` and unknown fields are ignored
        }
        return nil
    }

    private mutating func dispatch() -> ServerSentEvent? {
        defer {
            eventType = ""
            dataLines.removeAll()
        }
        guard !dataLines.isEmpty else { return nil }
        return ServerSentEvent(
            event: eventType.isEmpty ? "message" : eventType,
            data: dataLines.joined(separator: "\n"),
            id: lastEventID
        )
    }
}
