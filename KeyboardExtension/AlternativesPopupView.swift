import UIKit

final class AlternativesPopupView: UIView {

    private let alternatives: [String]
    private var cells: [UILabel] = []
    private(set) var highlightedIndex: Int?

    static let cellSize: CGFloat = 40
    static let cellSpacing: CGFloat = 2
    static let padding: CGFloat = 6

    var selectedAlternative: String? {
        highlightedIndex.map { alternatives[$0] }
    }

    private let accentColor: UIColor

    init(alternatives: [String], traitCollection: UITraitCollection? = nil) {
        self.alternatives = alternatives
        let tc = traitCollection ?? UITraitCollection.current
        self.accentColor = ThemeManager.shared.resolvedTheme(for: tc).accent
        super.init(frame: .zero)
        setup(traitCollection: tc)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout helpers

    static func size(for count: Int) -> CGSize {
        let width = CGFloat(count) * cellSize
            + CGFloat(max(0, count - 1)) * cellSpacing
            + padding * 2
        let height = cellSize + padding * 2
        return CGSize(width: width, height: height)
    }

    // MARK: - Private setup

    private func setup(traitCollection: UITraitCollection) {
        let theme = ThemeManager.shared.resolvedTheme(for: traitCollection)
        backgroundColor = theme.keyBackground
        layer.cornerRadius = 10
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 2)

        var xOffset = Self.padding
        for alt in alternatives {
            let label = UILabel()
            label.text = alt
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 22, weight: .regular)
            label.textColor = .label
            label.frame = CGRect(
                x: xOffset,
                y: Self.padding,
                width: Self.cellSize,
                height: Self.cellSize
            )
            label.layer.cornerRadius = 6
            label.clipsToBounds = true
            addSubview(label)
            cells.append(label)
            xOffset += Self.cellSize + Self.cellSpacing
        }
    }

    // MARK: - Selection tracking

    /// Updates which cell is highlighted based on the touch location given in
    /// the popup's superview coordinate space.
    func updateHighlight(forTouchAt locationInSuperview: CGPoint) {
        let localX = locationInSuperview.x - frame.minX

        var newIndex: Int? = nil
        for (i, cell) in cells.enumerated() {
            if localX >= cell.frame.minX - 1 && localX <= cell.frame.maxX + 1 {
                newIndex = i
                break
            }
        }

        // Clamp to first/last cell when touch is horizontally outside the popup.
        if newIndex == nil {
            if localX >= -Self.padding && localX < cells.first?.frame.minX ?? 0 {
                newIndex = 0
            } else if localX <= bounds.width + Self.padding
                        && localX > cells.last?.frame.maxX ?? bounds.width {
                newIndex = cells.count - 1
            }
        }

        guard newIndex != highlightedIndex else { return }

        if let prev = highlightedIndex, prev < cells.count {
            cells[prev].backgroundColor = .clear
            cells[prev].textColor = .label
        }
        if let curr = newIndex, curr < cells.count {
            cells[curr].backgroundColor = accentColor
            cells[curr].textColor = .white
        }
        highlightedIndex = newIndex
    }
}
