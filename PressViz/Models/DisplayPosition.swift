import Foundation

/// キー表示の位置（9箇所から選択可能）
enum DisplayPosition: String, CaseIterable, Codable, Sendable {
    case topLeft = "topLeft"
    case topCenter = "topCenter"
    case topRight = "topRight"
    case middleLeft = "middleLeft"
    case center = "center"
    case middleRight = "middleRight"
    case bottomLeft = "bottomLeft"
    case bottomCenter = "bottomCenter"
    case bottomRight = "bottomRight"

    var displayName: String {
        switch self {
        case .topLeft: "左上"
        case .topCenter: "上中央"
        case .topRight: "右上"
        case .middleLeft: "左中央"
        case .center: "中央"
        case .middleRight: "右中央"
        case .bottomLeft: "左下"
        case .bottomCenter: "下中央"
        case .bottomRight: "右下"
        }
    }

    var gridPosition: (row: Int, column: Int) {
        switch self {
        case .topLeft: (0, 0)
        case .topCenter: (0, 1)
        case .topRight: (0, 2)
        case .middleLeft: (1, 0)
        case .center: (1, 1)
        case .middleRight: (1, 2)
        case .bottomLeft: (2, 0)
        case .bottomCenter: (2, 1)
        case .bottomRight: (2, 2)
        }
    }
}
