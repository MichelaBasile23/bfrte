import SwiftUI
import DesignSystem

struct CommentModerationOptionsView: View {
    private struct Item {
        let title: String
        let iconName: IconName
        let tintColor: Color
    }

    private let items = [
        Item(
            title: Strings.approveTitle,
            iconName: .checkmarkCircle,
            tintColor: .DS.Foreground.brand(isJetpack: true)
        ),
        Item(
            title: Strings.pendingTitle,
            iconName: .clock,
            tintColor: .DS.Foreground.secondary
        ),
        Item(
            title: Strings.trashTitle,
            iconName: .trash,
            tintColor: .DS.Foreground.warning
        ),
        Item(
            title: Strings.spamTitle,
            iconName: .exclamationCircle,
            tintColor: .DS.Foreground.error
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: .DS.Padding.medium) {
            title
            optionsVStack
        }
        .padding(.horizontal, .DS.Padding.double)
        .background(Color.DS.Background.primary)
    }

    private var title: some View {
        Text(Strings.title)
            .font(.DS.Body.Emphasized.large)
            .foregroundStyle(Color.DS.Foreground.primary)
    }

    private var optionsVStack: some View {
        VStack(spacing: .DS.Padding.medium) {
            ForEach(items, id: \.title) { item in
                optionHStack(item: item)
            }
        }
    }

    private func optionHStack(item: Item) -> some View {
        HStack(spacing: .DS.Padding.double) {
            Image.DS.icon(named: item.iconName)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(item.tintColor)
                .frame(
                    width: .DS.Padding.medium,
                    height: .DS.Padding.medium
                )

            Text(item.title)
                .font(.DS.Body.large)
                .foregroundStyle(
                    Color.DS.Foreground.primary
                )

            Spacer()
        }
    }
}

private extension CommentModerationOptionsView {
    enum Strings {
        static let title = NSLocalizedString(
            "comment.moderation.sheet.title",
            value: "Choose comment status",
            comment: "Title for the comment moderation sheet."
        )
        static let approveTitle = NSLocalizedString(
            "comment.moderation.sheet.approve.title",
            value: "Approve",
            comment: "Approve option title for the comment moderation sheet."
        )
        static let pendingTitle = NSLocalizedString(
            "comment.moderation.sheet.pending.title",
            value: "Pending",
            comment: "Pending option title for the comment moderation sheet."
        )
        static let trashTitle = NSLocalizedString(
            "comment.moderation.sheet.trash.title",
            value: "Trash",
            comment: "Trash option title for the comment moderation sheet."
        )
        static let spamTitle = NSLocalizedString(
            "comment.moderation.sheet.spam.title",
            value: "Spam",
            comment: "Spam option title for the comment moderation sheet."
        )
    }
}

#Preview {
    CommentModerationOptionsView()
}
