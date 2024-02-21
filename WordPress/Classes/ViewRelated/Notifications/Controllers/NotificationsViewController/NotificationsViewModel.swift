final class NotificationsViewModel {
    enum Constants {
        static let lastSeenKey = "notifications_last_seen_time"
    }

    // MARK: - Type Aliases

    typealias ShareablePost = (url: String, title: String?)
    typealias PostReadyForShareCallback = (ShareablePost, IndexPath) -> Void

    // MARK: - Callbacks

    var onPostReadyForShare: PostReadyForShareCallback?

    // MARK: - Depdencies

    private let userDefaults: UserPersistentRepository
    private let notificationMediator: NotificationSyncMediatorProtocol?
    private let analyticsTracker: AnalyticsEventTracking.Type

    // MARK: - Init

    init(
        userDefaults: UserPersistentRepository,
        notificationMediator: NotificationSyncMediatorProtocol? = NotificationSyncMediator(),
        analyticsTracker: AnalyticsEventTracking.Type = WPAnalytics.self
    ) {
        self.userDefaults = userDefaults
        self.notificationMediator = notificationMediator
        self.analyticsTracker = analyticsTracker
    }

    /// The last time when user seen notifications
    private(set) var lastSeenTime: String? {
        get {
            return userDefaults.string(forKey: Constants.lastSeenKey)
        }
        set {
            userDefaults.set(newValue, forKey: Constants.lastSeenKey)
        }
    }

    func lastSeenChanged(timestamp: String?) {
        guard let timestamp,
              timestamp != lastSeenTime,
              let mediator = notificationMediator else {
            return
        }

        mediator.updateLastSeen(timestamp) { [weak self] error in
            guard error == nil else {
                return
            }

            self?.lastSeenTime = timestamp
        }
    }

    func didChangeDefaultAccount() {
        lastSeenTime = nil
    }

    func loadNotification(
        near note: Notification,
        allNotifications: [Notification],
        withIndexDelta delta: Int
    ) -> Notification? {
        guard let noteIndex = allNotifications.firstIndex(of: note) else {
            return nil
        }

        let targetIndex = noteIndex + delta
        guard targetIndex >= 0 && targetIndex < allNotifications.count else {
            return nil
        }

        func notMatcher(_ note: Notification) -> Bool {
            return note.kind != .matcher
        }

        if delta > 0 {
            return allNotifications
                .suffix(from: targetIndex)
                .first(where: notMatcher)
        } else {
            return allNotifications
                .prefix(through: targetIndex)
                .reversed()
                .first(where: notMatcher)
        }
    }

    // MARK: - Handling Inline Actions

    func sharePostActionTapped(with notification: Notification, at indexPath: IndexPath) {
        guard let url = notification.url else {
            return
        }
        let content: ShareablePost = (
            url: url,
            title: notification.title
        )
        self.onPostReadyForShare?(content, indexPath)
        self.trackInlineActionTapped(action: .sharePost)
    }
}

// MARK: - Analytics Tracking

private extension NotificationsViewModel {

    func trackInlineActionTapped(action: InlineAction) {
        self.analyticsTracker.track(.notificationsInlineActionTapped, properties: ["inline_action": action.rawValue])
    }

    enum InlineAction: String {
        case sharePost = "share_post"
        case commentLike = "comment_like"
        case postLike = "post_like"
    }
}
