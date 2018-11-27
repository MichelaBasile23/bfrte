import Foundation

class GutenbergSettings: NSObject {

    // MARK: - Enabled Editors Keys

    fileprivate let gutenbergEditorEnabledKey = "kUserDefaultsGutenbergEditorEnabled"

    // MARK: - Internal variables
    fileprivate let database: KeyValueDatabase

    // MARK: - Initialization
    init(database: KeyValueDatabase) {
        self.database = database
        super.init()
    }

    convenience override init() {
        self.init(database: UserDefaults() as KeyValueDatabase)
    }

    // MARK: Public accessors

    @objc func isGutenbergEnabled() -> Bool {
        return database.object(forKey: gutenbergEditorEnabledKey) as? Bool ?? false
    }

    @objc func toggleGutenberg() {
        if isGutenbergEnabled() {
            database.set(false, forKey: gutenbergEditorEnabledKey)
        } else {
            database.set(true, forKey: gutenbergEditorEnabledKey)
        }
    }

    // MARK: - Gutenberg Choice Logic

    /// Call this method to know if Gutenberg must be used for the specified post.
    ///
    /// - Parameters:
    ///     - post: the post that will be edited.
    ///
    /// - Returns: true if the post must be edited with Gutenberg.
    ///
    func mustUseGutenberg(for post: AbstractPost) -> Bool {
        return isGutenbergEnabled()
            && (!post.hasRemote() || post.containsGutenbergBlocks())
    }
}
