import SwiftUI

/// クリックエフェクトのビュー
struct ClickEffectView: View {
    let location: CGPoint
    let isDragging: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0

    var body: some View {
        Circle()
            .stroke(Color.blue, lineWidth: 3)
            .frame(width: 50, height: 50)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(location)
            .onAppear {
                if isDragging {
                    // ドラッグ中は固定表示
                    withAnimation(.easeOut(duration: 0.15)) {
                        scale = 1.0
                    }
                } else {
                    // 通常クリックはフェードアウト
                    withAnimation(.easeOut(duration: 0.4)) {
                        scale = 1.5
                        opacity = 0
                    }
                }
            }
            .onChange(of: isDragging) { _, newValue in
                if !newValue {
                    // ドラッグ終了時にフェードアウト
                    withAnimation(.easeOut(duration: 0.4)) {
                        scale = 1.5
                        opacity = 0
                    }
                }
            }
    }
}

/// クリックエフェクトコンテナ
struct ClickEffectContainer: View {
    let clicks: [ClickEffectItem]

    var body: some View {
        ZStack {
            ForEach(clicks) { click in
                ClickEffectView(location: click.location, isDragging: click.isDragging)
            }
        }
        .ignoresSafeArea()
    }
}

/// クリックエフェクトのアイテム
struct ClickEffectItem: Identifiable {
    let id: UUID
    var location: CGPoint
    let timestamp: Date
    var isDragging: Bool

    init(location: CGPoint, timestamp: Date = Date(), isDragging: Bool = false) {
        self.id = UUID()
        self.location = location
        self.timestamp = timestamp
        self.isDragging = isDragging
    }
}
