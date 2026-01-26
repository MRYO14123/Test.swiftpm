import SwiftUI

enum GameState {
    case idle
    case countdown
    case running
    case result
}

struct ContentView: View {
    @State private var gameState: GameState = .idle
    @State private var targetSeconds: Int = 10
    @State private var countdownText: String = ""
    @State private var startTime: Date?
    @State private var elapsedTime: Double = 0
    @State private var timer: Timer?
    @State private var countdownTimer: Timer?

    var body: some View {
        ZStack {
            // グラデーション背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.1, green: 0.2, blue: 0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // タイトル
                Text("体内時計チャレンジ")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(gameState == .idle ? 1 : 0.5)

                Spacer()

                // メイン表示エリア
                mainDisplayArea

                Spacer()

                // ターゲット時間表示
                if gameState != .idle {
                    targetTimeView
                }

                Spacer()

                // ボタン
                actionButton

                Spacer()
                    .frame(height: 50)
            }
            .padding()
        }
    }

    // メイン表示エリア
    @ViewBuilder
    private var mainDisplayArea: some View {
        ZStack {
            // 円形の背景
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)

            switch gameState {
            case .idle:
                VStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.cyan)
                    Text("準備OK?")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }

            case .countdown:
                Text(countdownText)
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .shadow(color: .cyan.opacity(0.5), radius: 10)

            case .running:
                VStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                        .symbolEffect(.pulse)
                    Text("計測中...")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }

            case .result:
                resultView
            }
        }
    }

    // ターゲット時間表示
    private var targetTimeView: some View {
        HStack(spacing: 8) {
            Image(systemName: "target")
                .foregroundColor(.orange)
            Text("\(targetSeconds)秒でストップ")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                )
        )
    }

    // 結果表示
    private var resultView: some View {
        VStack(spacing: 12) {
            Text(resultEmoji)
                .font(.system(size: 50))

            Text(String(format: "%.2f秒", elapsedTime))
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(resultColor)

            Text(resultMessage)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            Text("誤差: \(String(format: "%.2f", abs(elapsedTime - Double(targetSeconds))))秒")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    // アクションボタン
    private var actionButton: some View {
        Button(action: handleButtonTap) {
            HStack(spacing: 12) {
                Image(systemName: buttonIcon)
                    .font(.system(size: 20, weight: .semibold))
                Text(buttonText)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(width: 200, height: 60)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: buttonGradientColors),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: buttonGradientColors[0].opacity(0.5), radius: 10, y: 5)
        }
        .disabled(gameState == .countdown)
        .opacity(gameState == .countdown ? 0.5 : 1)
    }

    // ボタンのテキスト
    private var buttonText: String {
        switch gameState {
        case .idle, .result: return "Start"
        case .countdown: return "..."
        case .running: return "Stop"
        }
    }

    // ボタンのアイコン
    private var buttonIcon: String {
        switch gameState {
        case .idle, .result: return "play.fill"
        case .countdown: return "hourglass"
        case .running: return "stop.fill"
        }
    }

    // ボタンのグラデーション色
    private var buttonGradientColors: [Color] {
        switch gameState {
        case .idle, .result, .countdown:
            return [Color.cyan, Color.blue]
        case .running:
            return [Color.pink, Color.red]
        }
    }

    // 結果の絵文字
    private var resultEmoji: String {
        let diff = abs(elapsedTime - Double(targetSeconds))
        if diff < 0.5 { return "🎯" }
        if diff < 1 { return "🌟" }
        if diff < 3 { return "👏" }
        if diff < 5 { return "👍" }
        return "💪"
    }

    // 結果メッセージ
    private var resultMessage: String {
        let diff = abs(elapsedTime - Double(targetSeconds))
        if diff < 0.5 { return "完璧！神業です！" }
        if diff < 1 { return "すばらしい！\nほぼ完璧！" }
        if diff < 3 { return "いい感じ！\n体内時計バッチリ！" }
        if diff < 5 { return "まあまあ！\nもう少し！" }
        return "もう一度\nチャレンジ！"
    }

    // 結果の色
    private var resultColor: Color {
        let diff = abs(elapsedTime - Double(targetSeconds))
        if diff < 0.5 { return .yellow }
        if diff < 1 { return .cyan }
        if diff < 3 { return .green }
        if diff < 5 { return .orange }
        return .pink
    }

    // ボタンタップ処理
    private func handleButtonTap() {
        switch gameState {
        case .idle, .result:
            startGame()
        case .running:
            stopGame()
        case .countdown:
            break
        }
    }

    // ゲーム開始
    private func startGame() {
        targetSeconds = Int.random(in: 1...60)
        gameState = .countdown

        let countdownSequence = ["3", "2", "1", "Start!"]
        var index = 0

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if index < countdownSequence.count {
                countdownText = countdownSequence[index]
                index += 1
            }

            if index == countdownSequence.count {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startTimer()
                }
            }
        }
    }

    // タイマー開始
    private func startTimer() {
        gameState = .running
        startTime = Date()
    }

    // ゲーム停止
    private func stopGame() {
        if let start = startTime {
            elapsedTime = Date().timeIntervalSince(start)
        }
        timer?.invalidate()
        timer = nil
        gameState = .result
    }
}

#Preview {
    ContentView()
}
