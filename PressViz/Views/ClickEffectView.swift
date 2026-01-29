import SwiftUI

/// クリックエフェクトのビュー
struct ClickEffectView: View {
    let location: CGPoint
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
                withAnimation(.easeOut(duration: 0.4)) {
                    scale = 1.5
                    opacity = 0
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
                ClickEffectView(location: click.location)
            }
        }
        .ignoresSafeArea()
    }
}

/// クリックエフェクトのアイテム
struct ClickEffectItem: Identifiable {
    let id = UUID()
    let location: CGPoint
    let timestamp: Date
}
