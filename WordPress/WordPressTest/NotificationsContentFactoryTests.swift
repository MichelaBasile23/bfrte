import XCTest
@testable import WordPress

final class NotificationsContentFactoryTests: XCTestCase {
    private let contextManager = ContextManagerMock()
    private let entityName = Notification.classNameWithoutNamespaces()

    func testTextNotificationReturnsExpectedImplementationOfFormattableContent() throws {
        let subject = try NotificationContentFactory.content(from: [mockTextContentDictionary()], actionsParser: NotificationActionParser(), parent: loadLikeNotification()).first as? NotificationTextContent

        XCTAssertNotNil(subject)
    }

    func testCommentNotificationReturnsExpectedImplementationOfFormattableContent() throws {
        let subject = try NotificationContentFactory.content(from: [mockCommentContentDictionary()], actionsParser: NotificationActionParser(), parent: loadLikeNotification()).first as? FormattableCommentContent

        XCTAssertNotNil(subject)
    }

    func testUserNotificationReturnsExpectedImplementationOfFormattableContent() throws {
        let subject = try NotificationContentFactory.content(from: [mockUserContentDictionary()], actionsParser: NotificationActionParser(), parent: loadLikeNotification()).first as? FormattableUserContent

        XCTAssertNotNil(subject)
    }

    private func mockTextContentDictionary() throws -> JSONObject {
        return try .loadFile(named: "notifications-text-content.json")
    }

    private func mockCommentContentDictionary() throws -> JSONObject {
        return try .loadFile(named: "notifications-comment-content.json")
    }

    private func mockUserContentDictionary() throws -> JSONObject {
        return try .loadFile(named: "notifications-user-content.json")
    }

    func loadLikeNotification() throws -> WordPress.Notification {
        return try .fixture(fromFile: "notifications-like.json", insertInto: contextManager.mainContext)
    }
}
