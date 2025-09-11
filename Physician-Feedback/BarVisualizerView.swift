import UIKit

class BarVisualizerView: UIView {
    var numberOfBars = 100
    var barColor = UIColor.systemRed
    var barHeights: [CGFloat] = []
    var targetHeights: [CGFloat] = []
    var isPaused: Bool = true
    private let smoothing: CGFloat = 0.2

    override init(frame: CGRect) {
        super.init(frame: frame)
        barHeights = Array(repeating: 0, count: numberOfBars)
        targetHeights = Array(repeating: 0, count: numberOfBars)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        barHeights = Array(repeating: 0, count: numberOfBars)
        targetHeights = Array(repeating: 0, count: numberOfBars)
    }
    
    func reset() {
        barHeights = Array(repeating: 0, count: numberOfBars)
        targetHeights = Array(repeating: 0, count: numberOfBars)
        setNeedsDisplay()
    }
    
    func pause() {
        isPaused = true
    }

    func resume() {
        isPaused = false
    }

    func update(withLevel level: Float) {
        guard !isPaused else { return }
        
        let minLevel: Float = -40
        let maxLevel: Float = 0
        
        let clamped = min(max(level, minLevel), maxLevel)
        var normalized = (clamped - minLevel) / (maxLevel - minLevel)

        normalized = pow(normalized, 0.5)

        for i in 0..<(numberOfBars - 1) {
            targetHeights[i] = targetHeights[i + 1]
        }

        let newHeight = CGFloat(normalized) * bounds.height
        targetHeights[numberOfBars - 1] = newHeight

        for i in 0..<numberOfBars {
            if barHeights[i] < targetHeights[i] {
                barHeights[i] += (targetHeights[i] - barHeights[i]) * 0.4
            } else {
                barHeights[i] += (targetHeights[i] - barHeights[i]) * 0.05
            }
        }

        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.clear(rect)

        let centerY = bounds.height / 2
        let barWidth = bounds.width / CGFloat(numberOfBars) * 0.6
        let spacing = bounds.width / CGFloat(numberOfBars) * 0.4

        for i in 0..<numberOfBars {
            let x = CGFloat(i) * (barWidth + spacing)
            let barHeight = barHeights[i]

            // Draw bar symmetrical around center
            let barRect = CGRect(x: x,
                                 y: centerY - barHeight / 2,
                                 width: barWidth,
                                 height: barHeight)
            let path = UIBezierPath(roundedRect: barRect, cornerRadius: barWidth / 2)
            barColor.setFill()
            path.fill()
        }
    }
}
