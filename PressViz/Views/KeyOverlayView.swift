import SwiftUI

/// キー表示のオーバーレイビュー
struct KeyOverlayView: View {
    let keyText: String
    let position: DisplayPosition
    let screenFrame: CGRect
    let scale: Double

    private var scaledFontSize: CGFloat {
        32 * scale
    }

    private var scaledHorizontalPadding: CGFloat {
        20 * scale
    }

    private var scaledVerticalPadding: CGFloat {
        12 * scale
    }

    private var scaledCornerRadius: CGFloat {
        12 * scale
    }

    var body: some View {
        GeometryReader { geometry in
            Text(keyText)
                .font(.system(size: scaledFontSize, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, scaledHorizontalPadding)
                .padding(.vertical, scaledVerticalPadding)
                .background {
                    RoundedRectangle(cornerRadius: scaledCornerRadius, style: .continuous)
                        .fill(.black.opacity(0.75))
                        .shadow(color: .black.opacity(0.3), radius: 10 * scale, x: 0, y: 4 * scale)
                }
                .position(calculatePosition(in: geometry.size))
        }
        .ignoresSafeArea()
    }

    private func calculatePosition(in size: CGSize) -> CGPoint {
        let padding: CGFloat = 40

        let x: CGFloat
        let y: CGFloat

        switch position.gridPosition.column {
        case 0: // 左
            x = padding + 100
        case 1: // 中央
            x = size.width / 2
        case 2: // 右
            x = size.width - padding - 100
        default:
            x = size.width / 2
        }

        switch position.gridPosition.row {
        case 0: // 上
            y = padding + 30
        case 1: // 中央
            y = size.height / 2
        case 2: // 下
            y = size.height - padding - 30
        default:
            y = size.height / 2
        }

        return CGPoint(x: x, y: y)
    }
}
