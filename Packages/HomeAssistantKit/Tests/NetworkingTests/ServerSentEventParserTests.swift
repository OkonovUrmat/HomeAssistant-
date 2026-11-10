import XCTest
@testable import Networking

final class ServerSentEventParserTests: XCTestCase {
    private func parse(_ stream: String) -> [ServerSentEvent] {
        var parser = ServerSentEventParser()
        return stream
            .split(separator: "\n", omittingEmptySubsequences: false)
            .compactMap { parser.consume(line: String($0)) }
    }

    func testSingleDataEvent() {
        XCTAssertEqual(parse("data: hello\n\n"), [ServerSentEvent(data: "hello")])
    }

    func testNamedEventWithMultilineData() {
        let events = parse("event: delta\ndata: line one\ndata: line two\n\n")
        XCTAssertEqual(events, [ServerSentEvent(event: "delta", data: "line one\nline two")])
    }

    func testCommentsAndKeepAlivesAreIgnored() {
        XCTAssertEqual(parse(": ping\n\ndata: x\n\n"), [ServerSentEvent(data: "x")])
    }

    func testCarriageReturnsAreStripped() {
        XCTAssertEqual(parse("data: x\r\n\r\n"), [ServerSentEvent(data: "x")])
    }

    func testOnlyOneLeadingSpaceIsRemoved() {
        XCTAssertEqual(parse("data:  indented\n\n").first?.data, " indented")
        XCTAssertEqual(parse("data:tight\n\n").first?.data, "tight")
    }

    func testEventTypeResetsBetweenEventsButIDPersists() {
        let events = parse("id: 7\nevent: citation\ndata: a\n\ndata: b\n\n")
        XCTAssertEqual(events, [
            ServerSentEvent(event: "citation", data: "a", id: "7"),
            ServerSentEvent(event: "message", data: "b", id: "7"),
        ])
    }

    func testIncompleteEventIsNotDispatched() {
        XCTAssertTrue(parse("data: partial").isEmpty)
    }
}
