import UIKit

class DonutChartView: UIView {

    // MARK: Views

    private var segmentLayers = [CAShapeLayer]()

    private var titleStackView: UIStackView!
    private var titleLabel: UILabel!
    private var totalCountLabel: UILabel!
    private var chartContainer: UIView!
    private var legendStackView: UIStackView!

    // MARK: Configuration

    struct Segment: Identifiable {
        // Identifier required to keep track of ordering
        let id = UUID()
        let title: String
        let value: CGFloat
        let color: UIColor

        /// - Returns: A new Segment with the provided value
        func withValue(_ newValue: CGFloat) -> Segment {
            return Segment(title: title, value: newValue, color: color)
        }
    }

    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    var totalCount: CGFloat = 0 {
        didSet {
            totalCountLabel.text = Float(totalCount).abbreviatedString()
        }
    }

    private var segments: [Segment] = [] {
        didSet {
            segmentOrder = segments.map({ $0.id })
        }
    }

    // We keep track of segment IDs so we can keep the order consistent if we need to adjust segments later
    private var segmentOrder: [UUID] = []

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .basicBackground

        configureChartContainer()
        configureTitleViews()
        configureLegend()
        configureConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureChartContainer() {
        chartContainer = UIView()
        chartContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chartContainer)
    }

    private func configureTitleViews() {
        titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)

        totalCountLabel = UILabel()
        totalCountLabel.textAlignment = .center
        totalCountLabel.font = .preferredFont(forTextStyle: .title1).bold()

        titleStackView = UIStackView(arrangedSubviews: [titleLabel, totalCountLabel])

        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        titleStackView.axis = .vertical
        titleStackView.spacing = Constants.titleStackViewSpacing

        addSubview(titleStackView)
    }

    private func configureLegend() {
        legendStackView = UIStackView()
        legendStackView.translatesAutoresizingMaskIntoConstraints = false
        legendStackView.spacing = Constants.legendStackViewSpacing
        legendStackView.distribution = .equalSpacing

        addSubview(legendStackView)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            chartContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            chartContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            chartContainer.topAnchor.constraint(equalTo: topAnchor),

            legendStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            legendStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            legendStackView.topAnchor.constraint(equalTo: chartContainer.bottomAnchor, constant: Constants.chartToLegendSpacing),
            legendStackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.innerTextPadding),
            titleStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.innerTextPadding),
            titleStackView.centerYAnchor.constraint(equalTo: chartContainer.centerYAnchor),
            titleStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: Constants.innerTextPadding),
            titleStackView.bottomAnchor.constraint(lessThanOrEqualTo: chartContainer.bottomAnchor, constant: -Constants.innerTextPadding)
        ])
    }

    /// Initializes the chart display with the provided data.
    ///
    /// - Parameters:
    ///     - title: Displayed in the center of the chart
    ///     - totalCount: Displayed in the center of the chart and used to calculate segment sizes
    ///     - segments: Used for color, legend titles, and segment size
    func configure(title: String?, totalCount: CGFloat, segments: [Segment]) {
        if segments.reduce(0.0, { $0 + $1.value }) > totalCount {
            DDLogInfo("DonutChartView: Segment values should not total greater than 100%.")
        }

        self.title = title
        self.totalCount = totalCount
        self.segments = normalizedSegments(segments)

        segments.forEach({ legendStackView.addArrangedSubview(LegendView(segment: $0)) })

        layoutChart()
    }

    // Converts all segment to percentage values between 0 and 1, otherwise
    // extremely large values can throw things off when calculating segment sizes.
    private func normalizedSegments(_ segments: [Segment]) -> [Segment] {
        guard totalCount > 0 else {
            return segments
        }

        let filtered = segments.filter({ $0.value > 0 })
        return filtered.map({ $0.withValue($0.value / totalCount) })
    }

    private func layoutChart() {
        guard !bounds.isEmpty else {
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Clear out any existing segments
        segmentLayers.forEach({ $0.removeFromSuperlayer() })
        segmentLayers = []

        guard totalCount > 0 else {
            // We must have a total count greater than 0, as we use it to calculate percentages
            DDLogInfo("DonutChartView: TotalCount must be greater than 0 for chart initialization.")
            return
        }

        // Due to the size of the endcaps on segments, if a segment is too small we can't display it.
        // Here we'll increase the size of small segments if necessary. We loop through segments.count times
        // to ensure that after each adjustment the remaining segments are still an acceptable size.
        var displaySegments = adjustedSegmentsForDisplay(segments)
        for _ in 0..<segments.count-1 {
            displaySegments = adjustedSegmentsForDisplay(displaySegments)
        }

        var currentTotal: CGFloat = 0.0
        for segment in displaySegments {
            if segment.value == 0 {
                continue
            }

            let segmentLayer = makeSegmentLayer(segment)

            // Calculate the start and end of the new segment
            let segmentStartPercentage = currentTotal

            let segmentEndPercentage: CGFloat
            if segment.value == Constants.minimumSizeSegment {
                segmentEndPercentage = segmentStartPercentage + minimumSizePercentage
            } else {
                segmentStartPercentage + segment.value
            }

            currentTotal = segmentEndPercentage

            let startAngle = segmentStartPercentage.radiansFromPercent().radiansRotated(byDegrees: Constants.chartRotationDegrees) + endCapOffset
            let endAngle =  segmentEndPercentage.radiansFromPercent().radiansRotated(byDegrees: Constants.chartRotationDegrees) - endCapOffset

            let path = UIBezierPath(arcCenter: chartCenterPoint,
                                    radius: chartRadius,
                                    startAngle: startAngle,
                                    endAngle: endAngle,
                                    clockwise: true)
            segmentLayer.path = path.cgPath

            segmentLayers.append(segmentLayer)
        }

        segmentLayers.forEach({ chartContainer.layer.addSublayer($0) })

        CATransaction.commit()
    }

    /// Updates segments so that
    private func adjustedSegmentsForDisplay(_ segments: [Segment]) -> [Segment] {
        var totalAdjustment: CGFloat = 0.0

        var belowMinimumSegments: [Segment] = []
        var otherSegments: [Segment] = []

        for segment in segments {
            // Ignore 0 sized segments, as we won't display them
            guard segment.value > 0 else {
                continue
            }

            // If we've already marked this as a minimum size segment
            guard segment.value != Constants.minimumSizeSegment else {
                belowMinimumSegments.append(segment)
                continue
            }

            guard segment.value < minimumSizePercentage else {
                otherSegments.append(segment)
                continue
            }

            // If a segment is too small to fit on the chart, we'll make a note of how much we
            // need to adjust it to match the minimum, and add it to the array.
            let delta = minimumSizePercentage - segment.value
            totalAdjustment += delta
            belowMinimumSegments.append(segment)
        }

        guard belowMinimumSegments.count > 0 else {
            return segments
        }

        // Next we need to adjust the sizes of the other segments to account for the extra we added so that we end up back at 100%
        let adjustmentPerSegment = totalAdjustment / CGFloat(otherSegments.count)
        var allSegments: [Segment] = []

        allSegments.append(contentsOf: otherSegments.map({ $0.withValue($0.value - adjustmentPerSegment) }))
        allSegments.append(contentsOf: belowMinimumSegments.map({ $0.withValue(Constants.minimumSizeSegment) }))

        // Re-sort the new list based on the original ID order passed in when the chart was configured
        return allSegments.sorted(by: { segmentOrder.firstIndex(of: $0.id) ?? 0 < segmentOrder.firstIndex(of: $1.id) ?? 0 })
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if !segments.isEmpty {
            layoutChart()
        }
    }

    // MARK: Helpers

    private func makeSegmentLayer(_ segment: Segment) -> CAShapeLayer {
        let segmentLayer = CAShapeLayer()
        segmentLayer.frame = chartContainer.bounds
        segmentLayer.lineWidth = Constants.lineWidth
        segmentLayer.fillColor = UIColor.clear.cgColor
        segmentLayer.strokeColor = segment.color.cgColor
        segmentLayer.lineCap = .round

        return segmentLayer
    }

    private var chartCenterPoint: CGPoint {
        return CGPoint(x: chartContainer.bounds.midX, y: chartContainer.bounds.midY)
    }

    private var chartRadius: CGFloat {
        let smallestDimension = min(chartContainer.bounds.width, chartContainer.bounds.height)
        return (smallestDimension / 2.0) - (Constants.lineWidth / 2.0)
    }

    /// Offset used to adjust the endpoints of each chart segment so that the end caps
    /// don't overlap, as they draw from their center not from the line edge
    private var endCapOffset: CGFloat {
        return asin(Constants.lineWidth * 0.5 / chartRadius)
    }

    // How many % does a minimum size segment take up? (minimum size is 2 * endcap offset)
    private var minimumSizePercentage: CGFloat {
        return (endCapOffset * 2.0).percentFromRadians() + 0.01 // Just needs to be a fraction larger than the endcaps themselves
    }

    // MARK: Constants

    enum Constants {
        static let lineWidth: CGFloat = 16.0
        static let innerTextPadding: CGFloat = 24.0
        static let titleStackViewSpacing: CGFloat = 8.0
        static let legendStackViewSpacing: CGFloat = 8.0
        static let chartToLegendSpacing: CGFloat = 32.0

        // We'll rotate the chart back by 90 degrees so it starts at the top rather than the right
        static let chartRotationDegrees: CGFloat = -90.0

        // Used to denote a segment that is below or at the minimum size we can display
        static let minimumSizeSegment: CGFloat = -1
    }
}

// MARK: - Legend View

private class LegendView: UIView {
    let segment: DonutChartView.Segment

    init(segment: DonutChartView.Segment) {
        self.segment = segment

        super.init(frame: .zero)

        configureSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviews() {
        let indicator = UIView()
        indicator.backgroundColor = segment.color
        indicator.layer.cornerRadius = 6.0

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.text = segment.title

        let stackView = UIStackView(arrangedSubviews: [indicator, titleLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 8.0
        addSubview(stackView)

        NSLayoutConstraint.activate([
            indicator.widthAnchor.constraint(equalToConstant: 12.0),
            indicator.heightAnchor.constraint(equalToConstant: 12.0),

            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

private extension CGFloat {
    func radiansFromPercent() -> CGFloat {
        return self * 2.0 * CGFloat.pi
    }

    func percentFromRadians() -> CGFloat {
        return self / (CGFloat.pi * 2.0)
    }

    func radiansRotated(byDegrees rotationDegrees: CGFloat) -> CGFloat {
        return self + rotationDegrees.degreesToRadians()
    }

    func degreesToRadians() -> CGFloat {
        return self * CGFloat.pi / 180.0
    }
}
