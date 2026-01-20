import SwiftUI

// MARK: - 简单的图表组件

/// 环形进度图
struct CircularProgressView: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let foregroundColor: Color
    let backgroundColor: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    foregroundColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

/// 简单的柱状图
struct SimpleBarChart: View {
    let data: [BarData]
    let maxBarHeight: CGFloat

    init(data: [BarData], maxBarHeight: CGFloat = 200) {
        self.data = data
        self.maxBarHeight = maxBarHeight
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(data) { item in
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(item.color)
                        .frame(width: 30, height: barHeight(for: item.value))
                        .animation(.easeInOut, value: item.value)

                    Text(item.label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: maxBarHeight + 20)
    }

    private func barHeight(for value: Double) -> CGFloat {
        let maxValue = data.map(\.value).max() ?? 1
        let ratio = maxValue > 0 ? value / maxValue : 0
        return CGFloat(ratio) * maxBarHeight
    }
}

struct BarData: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

/// 简单的折线图
struct SimpleLineChart: View {
    let data: [Double]
    let color: Color
    let showDots: Bool

    init(data: [Double], color: Color = .blue, showDots: Bool = true) {
        self.data = data
        self.color = color
        self.showDots = showDots
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let maxVal = data.max() ?? 1
            let minVal = data.min() ?? 0
            let range = maxVal - minVal

            ZStack {
                // 背景网格线
                ForEach(0..<5) { i in
                    let y = CGFloat(i) * height / 4
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                }

                // 折线
                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) / CGFloat(data.count - 1) * width
                        let normalizedValue = range > 0 ? (value - minVal) / range : 0.5
                        let y = height - (CGFloat(normalizedValue) * height)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, lineWidth: 2)

                // 数据点
                if showDots {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                        let x = CGFloat(index) / CGFloat(data.count - 1) * width
                        let normalizedValue = range > 0 ? (value - minVal) / range : 0.5
                        let y = height - (CGFloat(normalizedValue) * height)

                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                }
            }
        }
        .frame(height: 150)
    }
}

/// 迷你趋势指示器
struct TrendIndicator: View {
    let value: Double
    let threshold: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: value >= 0 ? "arrow.up" : "arrow.down")
                .font(.caption2)
            Text("\(String(format: "%.2f", abs(value)))%")
                .font(.caption)
        }
        .foregroundColor(value >= 0 ? .green : .red)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((value >= 0 ? Color.green : Color.red).opacity(0.1))
        .cornerRadius(4)
    }
}

/// 资产分布饼图
struct AssetDistributionPie: View {
    let data: [PieSlice]

    var body: some View {
        ZStack {
            ForEach(Array(data.enumerated()), id: \.offset) { index, slice in
                PieSliceShape(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index)
                )
                .fill(slice.color)
                .overlay(
                    GeometryReader { geometry in
                        let midAngle = (startAngle(for: index) + endAngle(for: index)) / 2
                        let radius = min(geometry.size.width, geometry.size.height) / 2 * 0.65
                        let x = geometry.size.width / 2 + CGFloat(cos(midAngle)) * radius
                        let y = geometry.size.height / 2 + CGFloat(sin(midAngle)) * radius

                        Text("\(Int(slice.percentage))%")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .position(x: x, y: y)
                    }
                )
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var totalValue: Double {
        data.reduce(0) { $0 + $1.value }
    }

    private func startAngle(for index: Int) -> Double {
        let angle = data[0..<index].reduce(0) { $0 + $1.value }
        return (angle / totalValue) * 2 * .pi - .pi / 2
    }

    private func endAngle(for index: Int) -> Double {
        let angle = data[0...index].reduce(0) { $0 + $1.value }
        return (angle / totalValue) * 2 * .pi - .pi / 2
    }
}

struct PieSlice {
    let value: Double
    let color: Color
    var percentage: Double {
        // 计算会在父视图中完成
        0
    }
}

struct PieSliceShape: Shape {
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: Angle(radians: startAngle),
            endAngle: Angle(radians: endAngle),
            clockwise: false
        )
        path.closeSubpath()

        return path
    }
}

// MARK: - 预览

#Preview("Circular Progress") {
    VStack {
        CircularProgressView(
            progress: 0.75,
            lineWidth: 8,
            foregroundColor: .blue,
            backgroundColor: Color.gray.opacity(0.3)
        )
        .frame(width: 100, height: 100)

        Text("75%")
    }
}

#Preview("Bar Chart") {
    SimpleBarChart(data: [
        BarData(label: "1月", value: 100, color: .blue),
        BarData(label: "2月", value: 150, color: .green),
        BarData(label: "3月", value: 120, color: .orange),
        BarData(label: "4月", value: 180, color: .purple)
    ])
    .padding()
}

#Preview("Line Chart") {
    SimpleLineChart(data: [100, 120, 110, 140, 130, 160, 150])
        .padding()
}

#Preview("Trend Indicator") {
    HStack(spacing: 20) {
        TrendIndicator(value: 5.2, threshold: 0)
        TrendIndicator(value: -3.1, threshold: 0)
        TrendIndicator(value: 0.5, threshold: 0)
    }
    .padding()
}

#Preview("Pie Chart") {
    let data = [
        PieSlice(value: 40, color: .blue),
        PieSlice(value: 30, color: .green),
        PieSlice(value: 20, color: .orange),
        PieSlice(value: 10, color: .purple)
    ]
    AssetDistributionPie(data: data)
        .frame(width: 200, height: 200)
}
