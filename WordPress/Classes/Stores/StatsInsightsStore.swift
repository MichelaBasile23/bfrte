import Foundation
import WordPressKit
import WordPressFlux
import WidgetKit

enum InsightAction: Action {

    // Insights overview
    case receivedLastPostInsight(_ lastPostInsight: StatsLastPostInsight?, _ error: Error?)
    case receivedAllTimeStats(_ allTimeStats: StatsAllTimesInsight?, _ error: Error?)
    case receivedAnnualAndMostPopularTimeStats(_ annualAndMostPopularTime: StatsAnnualAndMostPopularTimeInsight?, _ error: Error?)
    case receivedDotComFollowers(_ followerStats: StatsDotComFollowersInsight?, _ error: Error?)
    case receivedEmailFollowers(_ followerStats: StatsEmailFollowersInsight?, _ error: Error?)
    case receivedPublicize(_ publicizeStats: StatsPublicizeInsight?, _ error: Error?)
    case receivedCommentsInsight(_ commentsInsight: StatsCommentsInsight?, _ error: Error?)
    case receivedTodaysStats(_ todaysStats: StatsTodayInsight?, _ error: Error?)
    case receivedPostingActivity(_ postingActivity: StatsPostingStreakInsight?, _ error: Error?)
    case receivedTagsAndCategories(_ tagsAndCategories: StatsTagsAndCategoriesInsight?, _ error: Error?)
    case refreshInsights(forceRefresh: Bool)

    // Insights details
    case receivedAllDotComFollowers(_ allDotComFollowers: StatsDotComFollowersInsight?, _ error: Error?)
    case receivedAllEmailFollowers(_ allDotComFollowers: StatsEmailFollowersInsight?, _ error: Error?)
    case refreshFollowers

    case receivedAllCommentsInsight(_ commentsInsight: StatsCommentsInsight?, _ error: Error?)
    case refreshComments

    case receivedAllTagsAndCategories(_ allTagsAndCategories: StatsTagsAndCategoriesInsight?, _ error: Error?)
    case refreshTagsAndCategories

    case receivedAllAnnual(_ allAnnual: StatsAllAnnualInsight?, _ error: Error?)
    case refreshAnnual
}

enum InsightQuery {
    case insights
    case allFollowers
    case allComments
    case allTagsAndCategories
    case allAnnual
}

struct InsightStoreState {

    // Insights overview

    // LPS

    var lastPostInsight: StatsLastPostInsight?
    var postStats: StatsPostDetails?
    var lastPostSummaryStatus: StoreFetchingStatus = .idle

    // Other Blocks

    var allTimeStats: StatsAllTimesInsight? {
        didSet {
            let allTimeWidgetStats = AllTimeWidgetStats(views: allTimeStats?.viewsCount,
                                                        visitors: allTimeStats?.visitorsCount,
                                                        posts: allTimeStats?.postsCount,
                                                        bestViews: allTimeStats?.bestViewsPerDayCount)
            storeAllTimeWidgetData(data: allTimeWidgetStats)
            StoreContainer.shared.statsWidgets.storeHomeWidgetData(widgetType: HomeWidgetAllTimeData.self, stats: allTimeWidgetStats)
        }
    }
    var allTimeStatus: StoreFetchingStatus = .idle

    var annualAndMostPopularTime: StatsAnnualAndMostPopularTimeInsight?
    var annualAndMostPopularTimeStatus: StoreFetchingStatus = .idle

    var dotComFollowers: StatsDotComFollowersInsight?
    var dotComFollowersStatus: StoreFetchingStatus = .idle

    var emailFollowers: StatsEmailFollowersInsight?
    var emailFollowersStatus: StoreFetchingStatus = .idle

    var publicizeFollowers: StatsPublicizeInsight?
    var publicizeFollowersStatus: StoreFetchingStatus = .idle

    var topCommentsInsight: StatsCommentsInsight?
    var commentsInsightStatus: StoreFetchingStatus = .idle

    var todaysStats: StatsTodayInsight? {
        didSet {
            let todayWidgetStats = TodayWidgetStats(views: todaysStats?.viewsCount,
                                                    visitors: todaysStats?.visitorsCount,
                                                    likes: todaysStats?.likesCount,
                                                    comments: todaysStats?.commentsCount)

            storeTodayWidgetData(data: todayWidgetStats)
            StoreContainer.shared.statsWidgets.storeHomeWidgetData(widgetType: HomeWidgetTodayData.self, stats: todayWidgetStats)
        }
    }
    var todaysStatsStatus: StoreFetchingStatus = .idle

    var postingActivity: StatsPostingStreakInsight?
    var postingActivityStatus: StoreFetchingStatus = .idle

    var topTagsAndCategories: StatsTagsAndCategoriesInsight?
    var tagsAndCategoriesStatus: StoreFetchingStatus = .idle

    // Insights details

    var allDotComFollowers: StatsDotComFollowersInsight?
    var allDotComFollowersStatus: StoreFetchingStatus = .idle

    var allEmailFollowers: StatsEmailFollowersInsight?
    var allEmailFollowersStatus: StoreFetchingStatus = .idle

    var allCommentsInsight: StatsCommentsInsight?
    var allCommentsInsightStatus: StoreFetchingStatus = .idle

    var allTagsAndCategories: StatsTagsAndCategoriesInsight?
    var allTagsAndCategoriesStatus: StoreFetchingStatus = .idle

    var allAnnual: StatsAllAnnualInsight?
    var allAnnualStatus: StoreFetchingStatus = .idle
}

class StatsInsightsStore: QueryStore<InsightStoreState, InsightQuery> {

    fileprivate static let cacheTTL: TimeInterval = 300 // 5 minutes

    init() {
        super.init(initialState: InsightStoreState())
    }

    /// A set containing all the data types associated with the currently visible Insights cards
    /// which defines the number and type of api calls we need to perform.
    var currentDataTypes: Set<InsightDataType> {
        Set(SiteStatsInformation.sharedInstance
                .getCurrentSiteInsights()  // The current visible cards
                .reduce(into: [InsightDataType]()) {
            $0.append(contentsOf: $1.insightsDataForSection)
        }) // And the respective associated data
    }

    override func onDispatch(_ action: Action) {

        guard let insightAction = action as? InsightAction else {
            return
        }

        switch insightAction {
        case .receivedLastPostInsight(let lastPostInsight, let error):
            receivedLastPostInsight(lastPostInsight, error)
        case .receivedAllTimeStats(let allTimeStats, let error):
            receivedAllTimeStats(allTimeStats, error)
        case .receivedAnnualAndMostPopularTimeStats(let mostPopularStats, let error):
            receivedAnnualAndMostPopularTimeStats(mostPopularStats, error)
        case .receivedDotComFollowers(let followerStats, let error):
            receivedDotComFollowers(followerStats, error)
        case .receivedEmailFollowers(let followerStats, let error):
            receivedEmailFollowers(followerStats, error)
        case .receivedCommentsInsight(let commentsInsight, let error):
            receivedCommentsInsight(commentsInsight, error)
        case .receivedPublicize(let items, let error):
            receivedPublicizeFollowers(items, error)
        case .receivedTodaysStats(let todaysStats, let error):
            receivedTodaysStats(todaysStats, error)
        case .receivedPostingActivity(let postingActivity, let error):
            receivedPostingActivity(postingActivity, error)
        case .receivedTagsAndCategories(let tagsAndCategories, let error):
            receivedTagsAndCategories(tagsAndCategories, error)
        case .refreshInsights(let forceRefresh):
            refreshInsights(forceRefresh: forceRefresh)
        case .receivedAllDotComFollowers(let allDotComFollowers, let error):
            receivedAllDotComFollowers(allDotComFollowers, error)
        case .receivedAllEmailFollowers(let allEmailFollowers, let error):
            receivedAllEmailFollowers(allEmailFollowers, error)
        case .refreshFollowers:
            refreshFollowers()
        case .receivedAllCommentsInsight(let allComments, let error):
            receivedAllCommentsInsight(allComments, error)
        case .refreshComments:
            refreshComments()
        case .receivedAllTagsAndCategories(let allTagsAndCategories, let error):
            receivedAllTagsAndCategories(allTagsAndCategories, error)
        case .refreshTagsAndCategories:
            refreshTagsAndCategories()
        case .receivedAllAnnual(let allAnnual, let error):
            receivedAllAnnual(allAnnual, error)
        case .refreshAnnual:
            refreshAnnual()
        }

        if !isFetchingOverview {
            DDLogInfo("Stats: Insights Overview refreshing operations finished.")
        }
    }

    override func queriesChanged() {
        super.queriesChanged()
        processQueries()
    }

    func persistToCoreData() {
        guard
            let siteID = SiteStatsInformation.sharedInstance.siteID,
            let blog = Blog.lookup(withID: siteID, in: ContextManager.shared.mainContext) else {
                return
        }

        _ = state.lastPostInsight.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.allTimeStats.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.annualAndMostPopularTime.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.dotComFollowers.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.emailFollowers.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.publicizeFollowers.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.topCommentsInsight.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.todaysStats.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.postingActivity.flatMap { StatsRecord.record(from: $0, for: blog) }
        _ = state.topTagsAndCategories.flatMap { StatsRecord.record(from: $0, for: blog) }

        try? ContextManager.shared.mainContext.save()
        setLastRefreshDate(Date(), for: siteID)
    }

}

// MARK: - Private Methods

private extension StatsInsightsStore {

    func processQueries() {

        guard !activeQueries.isEmpty else {
            // This being empty means a VC just unregistered from observing data.
            // Let's persist what we have an clear the in-memory store.
            persistToCoreData()
            state = InsightStoreState()
            return
        }

        activeQueries.forEach { query in
            switch query {
            case .insights:
                loadFromCache()
            case .allFollowers:
                if shouldFetchFollowers() {
                    fetchAllFollowers()
                }
            case .allComments:
                if shouldFetchComments() {
                    fetchAllComments()
                }
            case .allTagsAndCategories:
                if shouldFetchTagsAndCategories() {
                    fetchAllTagsAndCategories()
                }
            case .allAnnual:
                if shouldFetchAnnual() {
                    fetchAllAnnual()
                }
            }
        }
    }

    // MARK: - Insights Overview

    func fetchInsights(_ newInsightsFeatureFlag: Bool) {
        guard newInsightsFeatureFlag else {
            setAllFetchingStatus(.loading)
            fetchLastPostSummary()
            return
        }
        updateFetchingStatusForActiveCards(.loading)
        fetchInsightsCards()
    }

    func fetchInsightsCards() {

        guard let api = statsRemote() else {
            setAllFetchingStatus(.idle)
            return
        }

        currentDataTypes.forEach {
            fetchInsightsForCard(type: $0, api: api)
        }
    }

    func fetchInsightsForCard(type: InsightDataType, api: StatsServiceRemoteV2) {
        switch type {
        case .latestPost:
            api.getInsight { (lastPost: StatsLastPostInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching last posts insights: \(error.localizedDescription)")
                }
                self.actionDispatcher.dispatch(InsightAction.receivedLastPostInsight(lastPost, error))
                DDLogInfo("Stats: Insights - successfully fetched latest post summary")
            }
        case .allTime:
            api.getInsight { (allTimesStats: StatsAllTimesInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching all time insights: \(error.localizedDescription)")
                }
                self.actionDispatcher.dispatch(InsightAction.receivedAllTimeStats(allTimesStats, error))
                DDLogInfo("Stats: Insights - successfully fetched all time")
            }

        case .annualAndMostPopular:
            api.getInsight { (annualAndTime: StatsAnnualAndMostPopularTimeInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching annual/most popular time: \(error.localizedDescription)")
                }
                self.actionDispatcher.dispatch(InsightAction.receivedAnnualAndMostPopularTimeStats(annualAndTime, error))
                DDLogInfo("Stats: Insights - successfully fetched annual and most popular")
            }
        case .tagsAndCategories:
            api.getInsight { (tagsAndCategoriesInsight: StatsTagsAndCategoriesInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching tags and categories insight: \(error.localizedDescription)")
                }

                self.actionDispatcher.dispatch(InsightAction.receivedTagsAndCategories(tagsAndCategoriesInsight, error))
                DDLogInfo("Stats: Insights - successfully fetched tags and categories")
            }

        case .comments:
            api.getInsight { (commentsInsights: StatsCommentsInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching comment insights: \(error.localizedDescription)")
                }
                self.actionDispatcher.dispatch(InsightAction.receivedCommentsInsight(commentsInsights, error))
                DDLogInfo("Stats: Insights - successfully fetched comments")
            }
        case .followers:
            api.getInsight { (wpComFollowers: StatsDotComFollowersInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching WP.com followers: \(error.localizedDescription)")
                }
                self.actionDispatcher.dispatch(InsightAction.receivedDotComFollowers(wpComFollowers, error))
                DDLogInfo("Stats: Insights - successfully fetched wp.com followers")
            }

            api.getInsight { (emailFollowers: StatsEmailFollowersInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching email followers: \(error.localizedDescription)")
                }
                self.actionDispatcher.dispatch(InsightAction.receivedEmailFollowers(emailFollowers, error))
                DDLogInfo("Stats: Insights - successfully fetched email followers")
            }
        case .today:
            api.getInsight { (todayInsight: StatsTodayInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching today's insight: \(error.localizedDescription)")
                }

                self.actionDispatcher.dispatch(InsightAction.receivedTodaysStats(todayInsight, error))
                DDLogInfo("Stats: Insights - successfully fetched today")
            }
        case .postingActivity:
            api.getInsight(limit: 5000) { (streak: StatsPostingStreakInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching posting activity insight: \(error.localizedDescription)")
                }

                self.actionDispatcher.dispatch(InsightAction.receivedPostingActivity(streak, error))
                DDLogInfo("Stats: Insights - successfully fetched posting activity")
            }
        case .publicize:
            api.getInsight { (publicizeInsight: StatsPublicizeInsight?, error) in
                if let error = error {
                    DDLogError("Error fetching publicize insights: \(error.localizedDescription)")
                }
                self.actionDispatcher.dispatch(InsightAction.receivedPublicize(publicizeInsight, error))
                DDLogInfo("Stats: Insights - successfully fetched publicize")
            }
        }
    }


    func fetchOverview() {
        guard let api = statsRemote() else {
            setAllFetchingStatus(.idle)
            return
        }

        api.getInsight { (allTimesStats: StatsAllTimesInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching all time insights: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllTimeStats(allTimesStats, error))
        }

        api.getInsight { (wpComFollowers: StatsDotComFollowersInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching WP.com followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedDotComFollowers(wpComFollowers, error))
        }

        api.getInsight { (emailFollowers: StatsEmailFollowersInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching email followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedEmailFollowers(emailFollowers, error))
        }

        api.getInsight { (publicizeInsight: StatsPublicizeInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching publicize insights: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedPublicize(publicizeInsight, error))
        }

        api.getInsight { (annualAndTime: StatsAnnualAndMostPopularTimeInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching annual/most popular time: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAnnualAndMostPopularTimeStats(annualAndTime, error))
        }

        api.getInsight { (todayInsight: StatsTodayInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching today's insight: \(String(describing: error?.localizedDescription))")
            }

            self.actionDispatcher.dispatch(InsightAction.receivedTodaysStats(todayInsight, error))
        }

        api.getInsight { (commentsInsights: StatsCommentsInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching comment insights: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedCommentsInsight(commentsInsights, error))
        }

        api.getInsight { (tagsAndCategoriesInsight: StatsTagsAndCategoriesInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching tags and categories insight: \(String(describing: error?.localizedDescription))")
            }

            self.actionDispatcher.dispatch(InsightAction.receivedTagsAndCategories(tagsAndCategoriesInsight, error))
        }

        api.getInsight(limit: 5000) { (streak: StatsPostingStreakInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching posting activity insight: \(String(describing: error?.localizedDescription))")
            }

            self.actionDispatcher.dispatch(InsightAction.receivedPostingActivity(streak, error))
        }
    }

    func loadFromCache() {
        guard
            let siteID = SiteStatsInformation.sharedInstance.siteID,
            let blog = Blog.lookup(withID: siteID, in: ContextManager.shared.mainContext) else {
                return
        }

        transaction { state in
            state.lastPostInsight = StatsRecord.insight(for: blog, type: .lastPostInsight).flatMap { StatsLastPostInsight(statsRecordValues: $0.recordValues) }
            state.allTimeStats = StatsRecord.insight(for: blog, type: .allTimeStatsInsight).flatMap { StatsAllTimesInsight(statsRecordValues: $0.recordValues) }
            state.annualAndMostPopularTime = StatsRecord.insight(for: blog, type: .annualAndMostPopularTimes).flatMap { StatsAnnualAndMostPopularTimeInsight(statsRecordValues: $0.recordValues) }
            state.publicizeFollowers = StatsRecord.insight(for: blog, type: .publicizeConnection).flatMap { StatsPublicizeInsight(statsRecordValues: $0.recordValues) }
            state.todaysStats = StatsRecord.insight(for: blog, type: .today).flatMap { StatsTodayInsight(statsRecordValues: $0.recordValues) }
            state.postingActivity = StatsRecord.insight(for: blog, type: .streakInsight).flatMap { StatsPostingStreakInsight(statsRecordValues: $0.recordValues) }
            state.topTagsAndCategories = StatsRecord.insight(for: blog, type: .tagsAndCategories).flatMap { StatsTagsAndCategoriesInsight(statsRecordValues: $0.recordValues) }
            state.topCommentsInsight = StatsRecord.insight(for: blog, type: .commentInsight).flatMap { StatsCommentsInsight(statsRecordValues: $0.recordValues) }

            let followersInsight = StatsRecord.insight(for: blog, type: .followers)

            state.dotComFollowers = followersInsight.flatMap { StatsDotComFollowersInsight(statsRecordValues: $0.recordValues) }
            state.emailFollowers = followersInsight.flatMap { StatsEmailFollowersInsight(statsRecordValues: $0.recordValues) }
        }

        DDLogInfo("Insights load from cache")
    }

    func statsRemote() -> StatsServiceRemoteV2? {
        guard
            let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue,
            let timeZone = SiteStatsInformation.sharedInstance.siteTimeZone
            else {
                return nil
        }

        let wpApi = WordPressComRestApi.defaultApi(oAuthToken: SiteStatsInformation.sharedInstance.oauth2Token, userAgent: WPUserAgent.wordPress())
        return StatsServiceRemoteV2(wordPressComRestApi: wpApi, siteID: siteID, siteTimezone: timeZone)
    }

    func refreshInsights(forceRefresh: Bool = false) {
        guard shouldFetchOverview() else {
            DDLogInfo("Stats: Insights Overview refresh triggered while one was in progress.")
            return
        }

        if FeatureFlag.statsPerformanceImprovements.enabled {
            guard forceRefresh || hasCacheExpired else {
                DDLogInfo("Stats: Insights Overview refresh requested but we still have valid cache data.")
                return
            }
        }

        if forceRefresh {
            DDLogInfo("Stats: Forcing an Insights refresh.")
        }

        persistToCoreData()
        fetchInsights()
    }

    func fetchLastPostSummary() {
        guard let api = statsRemote() else {
            setAllFetchingStatus(.idle)
            state.lastPostSummaryStatus = .idle
            return
        }

        api.getInsight { (lastPost: StatsLastPostInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching last posts insights: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedLastPostInsight(lastPost, error))
        }
    }

    func fetchStatsForInsightsLatestPost() {
        guard let postID = getLastPostInsight()?.postID,
            let api = statsRemote() else {
            state.lastPostSummaryStatus = .idle
            return
        }

        api.getDetails(forPostID: postID) { (postStats: StatsPostDetails?, error: Error?) in
            if error != nil {
                DDLogInfo("Insights: Error fetching Post Stats: \(String(describing: error?.localizedDescription))")
            }
            DDLogInfo("Insights: Finished fetching post stats.")

            DispatchQueue.main.async {
                self.receivedPostStats(postStats, error)
                self.fetchOverview()
            }
        }
    }

    func receivedPostStats(_ postStats: StatsPostDetails?, _ error: Error?) {
        transaction { state in
            if postStats != nil {
                state.postStats = postStats
            }
            state.lastPostSummaryStatus = error != nil ? .error : .success
        }
    }

    func receivedLastPostInsight(_ lastPostInsight: StatsLastPostInsight?, _ error: Error?) {
        if lastPostInsight != nil {
            state.lastPostInsight = lastPostInsight
            fetchStatsForInsightsLatestPost()
            return
        }
        transaction { state in
            state.lastPostSummaryStatus = error != nil ? .error : .success
        }
        fetchOverview()
    }

    func receivedAllTimeStats(_ allTimeStats: StatsAllTimesInsight?, _ error: Error?) {
        transaction { state in
            if allTimeStats != nil {
                state.allTimeStats = allTimeStats
            }
            state.allTimeStatus = error != nil ? .error : .success
        }
    }

    func receivedAnnualAndMostPopularTimeStats(_ mostPopularStats: StatsAnnualAndMostPopularTimeInsight?, _ error: Error?) {
        transaction { state in
            if mostPopularStats != nil {
                state.annualAndMostPopularTime = mostPopularStats
            }
            state.annualAndMostPopularTimeStatus = error != nil ? .error : .success
        }
    }

    func receivedDotComFollowers(_ followerStats: StatsDotComFollowersInsight?, _ error: Error?) {
        transaction { state in
            if followerStats != nil {
                state.dotComFollowers = followerStats
            }
            state.dotComFollowersStatus = error != nil ? .error : .success
        }
    }

    func receivedEmailFollowers(_ followerStats: StatsEmailFollowersInsight?, _ error: Error?) {
        transaction { state in
            if followerStats != nil {
                state.emailFollowers = followerStats
            }
            state.emailFollowersStatus = error != nil ? .error : .success
        }
    }

    func receivedPublicizeFollowers(_ followerStats: StatsPublicizeInsight?, _ error: Error?) {
        transaction { state in
            if followerStats != nil {
                state.publicizeFollowers = followerStats
            }
            state.publicizeFollowersStatus = error != nil ? .error : .success
        }
    }

    func receivedCommentsInsight(_ commentsInsight: StatsCommentsInsight?, _ error: Error?) {
        transaction { state in
            if commentsInsight != nil {
                state.topCommentsInsight = commentsInsight
            }
            state.commentsInsightStatus = error != nil ? .error : .success
        }
    }

    func receivedTodaysStats(_ todaysStats: StatsTodayInsight?, _ error: Error?) {
        transaction { state in
            if todaysStats != nil {
                state.todaysStats = todaysStats
            }
            state.todaysStatsStatus = error != nil ? .error : .success
        }
    }

    func receivedPostingActivity(_ postingActivity: StatsPostingStreakInsight?, _ error: Error?) {
        transaction { state in
            if postingActivity != nil {
                state.postingActivity = postingActivity
            }
            state.postingActivityStatus = error != nil ? .error : .success
        }
    }

    func receivedTagsAndCategories(_ tagsAndCategories: StatsTagsAndCategoriesInsight?, _ error: Error?) {
        transaction { state in
            if tagsAndCategories != nil {
                state.topTagsAndCategories = tagsAndCategories
            }
            state.tagsAndCategoriesStatus = error != nil ? .error : .success
        }
    }

    func setAllFetchingStatus(_ status: StoreFetchingStatus) {
        state.lastPostSummaryStatus = status
        state.allTimeStatus = status
        state.annualAndMostPopularTimeStatus = status
        state.dotComFollowersStatus = status
        state.emailFollowersStatus = status
        state.todaysStatsStatus = status
        state.tagsAndCategoriesStatus = status
        state.publicizeFollowersStatus = status
        state.commentsInsightStatus = status
        state.postingActivityStatus = status
    }

    func shouldFetchOverview() -> Bool {
        return !isFetchingOverview
    }

    // MARK: - Insights Details

    func fetchAllFollowers() {
        guard let api = statsRemote() else {
            return
        }

        state.allDotComFollowersStatus = .loading
        state.allEmailFollowersStatus = .loading

        // The followers API returns a maximum of 100 results.
        // Using a limit of 0 returns the default 20 results.
        // So use limit 100 to get max results.

        api.getInsight(limit: 100) { (dotComFollowers: StatsDotComFollowersInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching dotCom Followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllDotComFollowers(dotComFollowers, error))
        }

          api.getInsight(limit: 100) { (emailFollowers: StatsEmailFollowersInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching email Followers: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllEmailFollowers(emailFollowers, error))
        }
    }

    func fetchAllComments() {
        guard let api = statsRemote() else {
            return
        }

        state.allCommentsInsightStatus = .loading

        // The API doesn't work when we specify `0` here, like most of the other endpoints do, unfortunately...
        // 1000 was chosen as an arbitrarily large number that should be "big enough" for all of our users.

        api.getInsight(limit: 1000) {(allComments: StatsCommentsInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching all comments: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllCommentsInsight(allComments, error))
        }
    }

    func fetchAllTagsAndCategories() {
        guard let api = statsRemote() else {
            return
        }

        state.allTagsAndCategoriesStatus = .loading

        // See the comment about the limit in the method above.
        api.getInsight(limit: 1000) { (allTagsAndCategories: StatsTagsAndCategoriesInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching all tags and categories: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllTagsAndCategories(allTagsAndCategories, error))
        }
    }

    func fetchAllAnnual() {
        guard let api = statsRemote() else {
            return
        }

        state.allAnnualStatus = .loading

        api.getInsight { (allAnnual: StatsAllAnnualInsight?, error) in
            if error != nil {
                DDLogInfo("Error fetching all annual: \(String(describing: error?.localizedDescription))")
            }
            self.actionDispatcher.dispatch(InsightAction.receivedAllAnnual(allAnnual, error))
        }
    }

    func receivedAllDotComFollowers(_ allDotComFollowers: StatsDotComFollowersInsight?, _ error: Error?) {
        transaction { state in
            if allDotComFollowers != nil {
                state.allDotComFollowers = allDotComFollowers
            }
            state.allDotComFollowersStatus = error != nil ? .error : .success
        }
    }

    func receivedAllEmailFollowers(_ allEmailFollowers: StatsEmailFollowersInsight?, _ error: Error?) {
        transaction { state in
            if allEmailFollowers != nil {
                state.allEmailFollowers = allEmailFollowers
            }
            state.allEmailFollowersStatus = error != nil ? .error : .success
        }
    }

    func refreshFollowers() {
        guard shouldFetchFollowers() else {
            DDLogInfo("Stats Insights Followers refresh triggered while one was in progress.")
            return
        }

        fetchAllFollowers()
    }

    func shouldFetchFollowers() -> Bool {
        return !isFetchingAllFollowers
    }

    func receivedAllCommentsInsight(_ allCommentsInsight: StatsCommentsInsight?, _ error: Error?) {
        transaction { state in
            if allCommentsInsight != nil {
                state.allCommentsInsight = allCommentsInsight
            }
            state.allCommentsInsightStatus = error != nil ? .error : .success
        }
    }

    func refreshComments() {
        guard shouldFetchComments() else {
            DDLogInfo("Stats Insights Comments refresh triggered while one was in progress.")
            return
        }

        fetchAllComments()
    }

    func shouldFetchComments() -> Bool {
        return !isFetchingComments
    }

    func receivedAllTagsAndCategories(_ allTagsAndCategories: StatsTagsAndCategoriesInsight?, _ error: Error?) {
        transaction { state in
            if allTagsAndCategories != nil {
                state.allTagsAndCategories = allTagsAndCategories
            }
            state.allTagsAndCategoriesStatus = error != nil ? .error : .success
        }
    }

    func refreshTagsAndCategories() {
        guard shouldFetchTagsAndCategories() else {
            DDLogInfo("Stats Insights Tags And Categories refresh triggered while one was in progress.")
            return
        }

        fetchAllTagsAndCategories()
    }

    func shouldFetchTagsAndCategories() -> Bool {
        return !isFetchingTagsAndCategories
    }

    func receivedAllAnnual(_ allAnnual: StatsAllAnnualInsight?, _ error: Error?) {
        transaction { state in
            if allAnnual != nil {
                state.allAnnual = allAnnual
            }
            state.allAnnualStatus = error != nil ? .error : .success
        }
    }

    func refreshAnnual() {
        guard shouldFetchAnnual() else {
            DDLogInfo("Stats Insights Annual refresh triggered while one was in progress.")
            return
        }

        fetchAllAnnual()
    }

    func shouldFetchAnnual() -> Bool {
        return !isFetchingAnnual
    }

    // MARK: - Cache expiry

    var hasCacheExpired: Bool {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID,
              let date = lastRefreshDate(for: siteID) else {
                  return true
              }

        let interval = Date().timeIntervalSince(date)
        let expired = interval > StatsInsightsStore.cacheTTL

        let intervalLogMessage = "(\(String(format: "%.2f", interval))s since last refresh)"
        DDLogInfo("Stats: Insights cache for site \(siteID) has \(expired ? "" : "not ")expired \(intervalLogMessage).")

        return expired
    }

    func lastRefreshDate(for siteID: NSNumber) -> Date? {
        if let date = UserDefaults.standard.object(forKey: "\(CacheUserDefaultsKeys.lastRefreshDatePrefix)\(siteID)") as? Date {
            return date
        }

        return nil
    }

    func setLastRefreshDate(_ date: Date, for siteID: NSNumber) {
        guard FeatureFlag.statsPerformanceImprovements.enabled else {
            return
        }

        UserDefaults.standard.set(date, forKey: "\(CacheUserDefaultsKeys.lastRefreshDatePrefix)\(siteID)")
    }

    private enum CacheUserDefaultsKeys {
        static let lastRefreshDatePrefix: String = "StatsStoreLastRefreshDate-"
    }
}

// MARK: - Public Accessors

extension StatsInsightsStore {

    func getLastPostInsight() -> StatsLastPostInsight? {
        return state.lastPostInsight
    }

    func getPostStats() -> StatsPostDetails? {
        return state.postStats
    }

    func getAllTimeStats() -> StatsAllTimesInsight? {
        return state.allTimeStats
    }

    func getAnnualAndMostPopularTime() -> StatsAnnualAndMostPopularTimeInsight? {
        return state.annualAndMostPopularTime
    }

    func getDotComFollowers() -> StatsDotComFollowersInsight? {
        return state.dotComFollowers
    }

    func getEmailFollowers() -> StatsEmailFollowersInsight? {
        return state.emailFollowers
    }

    func getPublicize() -> StatsPublicizeInsight? {
        return state.publicizeFollowers
    }

    func getTopCommentsInsight() -> StatsCommentsInsight? {
        return state.topCommentsInsight
    }

    func getTodaysStats() -> StatsTodayInsight? {
        return state.todaysStats
    }

    func getTopTagsAndCategories() -> StatsTagsAndCategoriesInsight? {
        return state.topTagsAndCategories
    }

    func getPostingActivity() -> StatsPostingStreakInsight? {
        return state.postingActivity
    }
    /// Summarizes the daily posting count for the month in the given date.
    /// Returns an array containing every day of the month and associated post count.
    ///
    func getMonthlyPostingActivityFor(date: Date) -> [PostingStreakEvent] {

        let calendar = Calendar.autoupdatingCurrent
        let components = calendar.dateComponents([.month, .year], from: date)

        guard
            let month = components.month,
            let year = components.year
            else {
                return []
        }

        let postingEvents = state.postingActivity?.postingEvents ?? []

        // This gives a range of how many days there are in a given month...
        let rangeOfMonth = calendar.range(of: .day, in: .month, for: date) ?? 0..<0

        let mappedMonth = rangeOfMonth
            // then we create a `Date` representing each of those days
            .compactMap {
                return calendar.date(from: DateComponents(year: year, month: month, day: $0))
            }
            // and pick out a relevant `PostingStreakEvent` from data we have or return
            // an empty one.
            .map { (date: Date) -> PostingStreakEvent in
                if let postingEvent = postingEvents.first(where: { event in return event.date == date }) {
                    return postingEvent
                }
                return PostingStreakEvent(date: date, postCount: 0)
        }

        return mappedMonth

    }

    func getYearlyPostingActivityFrom(date: Date) -> [[PostingStreakEvent]] {
        // We operate on a "reversed" range since we want least-recent months first.
        return (0...11).reversed().compactMap {
            guard
                let monthDate = Calendar.current.date(byAdding: .month, value: -$0, to: date)
                else {
                    return nil
            }

            return getMonthlyPostingActivityFor(date: monthDate)
        }
    }

    func getAllDotComFollowers() -> StatsDotComFollowersInsight? {
        return state.allDotComFollowers
    }

    func getAllEmailFollowers() -> StatsEmailFollowersInsight? {
        return state.allEmailFollowers
    }

    func getAllCommentsInsight() -> StatsCommentsInsight? {
        return state.allCommentsInsight
    }

    func getAllTagsAndCategories() -> StatsTagsAndCategoriesInsight? {
        return state.allTagsAndCategories
    }

    func getAllAnnual() -> StatsAllAnnualInsight? {
        return state.allAnnual
    }

    var lastPostSummaryStatus: StoreFetchingStatus {
        return state.lastPostSummaryStatus
    }

    var allTimeStatus: StoreFetchingStatus {
        return state.allTimeStatus
    }

    var todaysStatsStatus: StoreFetchingStatus {
        return state.todaysStatsStatus
    }

    var tagsAndCategoriesStatus: StoreFetchingStatus {
        return state.tagsAndCategoriesStatus
    }

    var publicizeFollowersStatus: StoreFetchingStatus {
        return state.publicizeFollowersStatus
    }

    var commentsInsightStatus: StoreFetchingStatus {
        return state.commentsInsightStatus
    }

    var postingActivityStatus: StoreFetchingStatus {
        return state.postingActivityStatus
    }

    var followersTotalsStatus: StoreFetchingStatus {
        switch (state.dotComFollowersStatus, state.emailFollowersStatus) {
        case (let a, let b) where a == .loading || b == .loading:
            return .loading
        case (let a, let b) where a == .error || b == .error:
            return .error
        case (.success, .success):
            return .success
        default:
            return .idle
        }
    }

    var annualAndMostPopularTimeStatus: StoreFetchingStatus {
        return state.annualAndMostPopularTimeStatus
    }

    var isFetchingLastPostSummary: Bool {
        return lastPostSummaryStatus == .loading
    }

    var isFetchingOverview: Bool {
        /*
         * Use reflection here to inspect all the members of type StoreFetchingStatus
         * with value .loading. If at least one exists then the store is still fetching the overview.
         */
        let mirror = Mirror(reflecting: state)
        return mirror.children.compactMap { $0.value as? StoreFetchingStatus }.first { $0 == .loading } != nil
    }

    var isFetchingAllFollowers: Bool {
        return state.allDotComFollowersStatus == .loading ||
                state.allEmailFollowersStatus == .loading
    }

    var allDotComFollowersStatus: StoreFetchingStatus {
        return state.allDotComFollowersStatus
    }

    var allEmailFollowersStatus: StoreFetchingStatus {
        return state.allEmailFollowersStatus
    }

    var fetchingFollowersStatus: StoreFetchingStatus {
        switch (state.allDotComFollowersStatus, state.allEmailFollowersStatus) {
        case (let a, let b) where a == .loading || b == .loading:
            return .loading
        case (.error, .error):
            return .error
        case (let a, let b) where a == .success || b == .success:
            return .success
        default:
            return .idle
        }
    }

    var allCommentsInsightStatus: StoreFetchingStatus {
        return state.allCommentsInsightStatus
    }

    var isFetchingComments: Bool {
        return allCommentsInsightStatus == .loading
    }

    var allTagsAndCategoriesStatus: StoreFetchingStatus {
        return state.allTagsAndCategoriesStatus
    }

    var isFetchingTagsAndCategories: Bool {
        return allTagsAndCategoriesStatus == .loading
    }

    var allAnnualStatus: StoreFetchingStatus {
        return state.allAnnualStatus
    }

    var isFetchingAnnual: Bool {
        return allAnnualStatus == .loading
    }

    var fetchingOverviewHasFailed: Bool {
        /*
         * Use reflection here to inspect all the members of type StoreFetchingStatus
         * with value different from .error.
         * If the result is nil the store failed loading the overview.
         */
        let mirror = Mirror(reflecting: state)
        return mirror.children.compactMap { $0.value as? StoreFetchingStatus }.first { $0 != .error } == nil
    }

    func fetchingFailed(for query: InsightQuery) -> Bool {
        switch query {
        case .insights:
            return fetchingOverviewHasFailed
        case .allFollowers:
            return fetchingFollowersStatus == .error
        case .allComments:
            return state.allCommentsInsightStatus == .error
        case .allTagsAndCategories:
            return state.allTagsAndCategoriesStatus == .error
        case .allAnnual:
            return state.allAnnualStatus == .error
        }
    }
}

// MARK: - Widget Data

private extension InsightStoreState {

    func storeTodayWidgetData(data: TodayWidgetStats) {
        guard widgetUsingCurrentSite() else {
            return
        }

        data.saveData()
    }

    func storeAllTimeWidgetData(data: AllTimeWidgetStats) {
        guard widgetUsingCurrentSite() else {
            return
        }

        data.saveData()
    }

    func widgetUsingCurrentSite() -> Bool {
        // Only store data if the widget is using the current site
        guard let sharedDefaults = UserDefaults(suiteName: WPAppGroupName),
            let widgetSiteID = sharedDefaults.object(forKey: WPStatsTodayWidgetUserDefaultsSiteIdKey) as? NSNumber,
            widgetSiteID == SiteStatsInformation.sharedInstance.siteID  else {
                return false
        }
        return true
    }
}

// MARK: - iOS 14 Widgets Data
private extension InsightStoreState {

    private func storeHomeWidgetData<T: HomeWidgetData>(widgetType: T.Type, stats: Codable) {
        guard #available(iOS 14.0, *),
              let siteID = SiteStatsInformation.sharedInstance.siteID else {
            return
        }

        var homeWidgetCache = T.read() ?? initializeHomeWidgetData(type: widgetType)
        guard let oldData = homeWidgetCache[siteID.intValue] else {
            DDLogError("StatsWidgets: Failed to find a matching site")
            return
        }

        guard let blog = Blog.lookup(withID: siteID, in: ContextManager.shared.mainContext) else {
            DDLogError("StatsWidgets: the site does not exist anymore")
            // if for any reason that site does not exist anymore, remove it from the cache.
            homeWidgetCache.removeValue(forKey: siteID.intValue)
            T.write(items: homeWidgetCache)
            return
        }
        var widgetKind = ""
        if widgetType == HomeWidgetTodayData.self, let stats = stats as? TodayWidgetStats {

            widgetKind = WPHomeWidgetTodayKind

            homeWidgetCache[siteID.intValue] = HomeWidgetTodayData(siteID: siteID.intValue,
                                                                   siteName: blog.title ?? oldData.siteName,
                                                                   url: blog.url ?? oldData.url,
                                                                   timeZone: blog.timeZone,
                                                                   date: Date(),
                                                                   stats: stats) as? T


        } else if widgetType == HomeWidgetAllTimeData.self, let stats = stats as? AllTimeWidgetStats {
            widgetKind = WPHomeWidgetAllTimeKind

            homeWidgetCache[siteID.intValue] = HomeWidgetAllTimeData(siteID: siteID.intValue,
                                                                     siteName: blog.title ?? oldData.siteName,
                                                                     url: blog.url ?? oldData.url,
                                                                     timeZone: blog.timeZone,
                                                                     date: Date(),
                                                                     stats: stats) as? T
        }

        T.write(items: homeWidgetCache)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)


    }

    private func initializeHomeWidgetData<T: HomeWidgetData>(type: T.Type) -> [Int: T] {
        let blogService = BlogService(managedObjectContext: ContextManager.shared.mainContext)

        return blogService.visibleBlogsForWPComAccounts().reduce(into: [Int: T]()) { result, element in
            if let blogID = element.dotComID,
               let url = element.url,
               let blog = Blog.lookup(withID: blogID, in: ContextManager.shared.mainContext) {
                // set the title to the site title, if it's not nil and not empty; otherwise use the site url
                let title = (element.title ?? url).isEmpty ? url : element.title ?? url
                let timeZone = blog.timeZone
                if type == HomeWidgetTodayData.self {
                    result[blogID.intValue] = HomeWidgetTodayData(siteID: blogID.intValue,
                                                                  siteName: title,
                                                                  url: url,
                                                                  timeZone: timeZone,
                                                                  date: Date(),
                                                                  stats: TodayWidgetStats()) as? T
                } else if type == HomeWidgetAllTimeData.self {
                    result[blogID.intValue] = HomeWidgetAllTimeData(siteID: blogID.intValue,
                                                                    siteName: title,
                                                                    url: url,
                                                                    timeZone: timeZone,
                                                                    date: Date(),
                                                                    stats: AllTimeWidgetStats()) as? T
                }
            }
        }
    }
}

// refresh iOS 14 widgets at login/logout
private extension StatsInsightsStore {
    func observeAccountChangesForWidgets() {
        guard #available(iOS 14.0, *) else {
            return
        }


        NotificationCenter.default.addObserver(forName: .WPAccountDefaultWordPressComAccountChanged,
                                               object: nil,
                                               queue: nil) { notification in
            HomeWidgetTodayData.delete()
            WidgetCenter.shared.reloadTimelines(ofKind: WPHomeWidgetTodayKind)
            HomeWidgetAllTimeData.delete()
            WidgetCenter.shared.reloadTimelines(ofKind: WPHomeWidgetAllTimeKind)

        }
    }
}
