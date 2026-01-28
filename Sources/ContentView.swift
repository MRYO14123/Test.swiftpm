import SwiftUI

enum GameState {
    case idle
    case countdown
    case running
    case result
}

// 速度倍率
enum SpeedMultiplier: Double, CaseIterable {
    case slow = 0.5
    case normal = 1.0
    case fast = 1.5
    case veryFast = 2.0
    case ultraFast = 3.0

    var displayName: String {
        switch self {
        case .slow: return "0.5x"
        case .normal: return "1x"
        case .fast: return "1.5x"
        case .veryFast: return "2x"
        case .ultraFast: return "3x"
        }
    }

    var color: Color {
        switch self {
        case .slow: return .green
        case .normal: return .cyan
        case .fast: return .yellow
        case .veryFast: return .orange
        case .ultraFast: return .red
        }
    }

    // 難易度の説明
    var difficultyLabel: String {
        switch self {
        case .slow: return "簡単"
        case .normal: return "普通"
        case .fast: return "やや難"
        case .veryFast: return "難しい"
        case .ultraFast: return "超難"
        }
    }

    static func random() -> SpeedMultiplier {
        allCases.randomElement() ?? .normal
    }
}

// ゲーム記録モデル
struct GameRecord: Identifiable, Codable {
    let id: UUID
    let targetSeconds: Int
    let elapsedTime: Double
    let difference: Double
    let speedMultiplier: Double
    let date: Date

    init(targetSeconds: Int, elapsedTime: Double, speedMultiplier: Double = 1.0) {
        self.id = UUID()
        self.targetSeconds = targetSeconds
        self.elapsedTime = elapsedTime
        self.difference = abs(elapsedTime - Double(targetSeconds))
        self.speedMultiplier = speedMultiplier
        self.date = Date()
    }

    var speedDisplayName: String {
        switch speedMultiplier {
        case 0.5: return "0.5x"
        case 1.0: return "1x"
        case 1.5: return "1.5x"
        case 2.0: return "2x"
        case 3.0: return "3x"
        default: return "\(speedMultiplier)x"
        }
    }
}

// ランキング管理
class RankingManager: ObservableObject {
    @Published var records: [GameRecord] = []
    private let key = "gameRecords_v2"

    init() {
        loadRecords()
    }

    func addRecord(_ record: GameRecord) {
        records.append(record)
        records.sort { $0.difference < $1.difference }
        // 上位20件のみ保持
        if records.count > 20 {
            records = Array(records.prefix(20))
        }
        saveRecords()
    }

    func clearRecords() {
        records = []
        saveRecords()
    }

    private func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([GameRecord].self, from: data) {
            records = decoded
        }
    }

    func getRank(for difference: Double) -> Int? {
        let sorted = records.sorted { $0.difference < $1.difference }
        if let index = sorted.firstIndex(where: { $0.difference >= difference }) {
            return index + 1
        }
        return records.count + 1
    }
}

struct ContentView: View {
    @State private var gameState: GameState = .idle
    @State private var targetSeconds: Int = 10
    @State private var countdownText: String = ""
    @State private var startTime: Date?
    @State private var elapsedTime: Double = 0
    @State private var timer: Timer?
    @State private var countdownTimer: Timer?
    @State private var showRanking = false
    @State private var currentRank: Int?
    @State private var currentSpeed: SpeedMultiplier = .normal
    @StateObject private var rankingManager = RankingManager()

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
                // ヘッダー（ランキングボタン）
                HStack {
                    Spacer()
                    Button(action: { showRanking = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trophy.fill")
                            Text("ランキング")
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.yellow.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // タイトル
                Text("体内時計チャレンジ")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(gameState == .idle ? 1 : 0.5)

                Spacer()

                // メイン表示エリア
                mainDisplayArea

                Spacer()

                // ターゲット時間と速度表示
                if gameState != .idle {
                    VStack(spacing: 12) {
                        targetTimeView
                        speedIndicatorView
                    }
                }

                Spacer()

                // ボタン
                actionButton

                Spacer()
                    .frame(height: 50)
            }
            .padding()
        }
        .sheet(isPresented: $showRanking) {
            RankingView(rankingManager: rankingManager)
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

    // 速度インジケーター
    private var speedIndicatorView: some View {
        HStack(spacing: 8) {
            Image(systemName: "hare.fill")
                .foregroundColor(currentSpeed.color)
            Text("時間の流れ: \(currentSpeed.displayName) (\(currentSpeed.difficultyLabel))")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(currentSpeed.color)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(currentSpeed.color.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(currentSpeed.color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // 結果表示
    private var resultView: some View {
        VStack(spacing: 8) {
            Text(resultEmoji)
                .font(.system(size: 36))

            Text(String(format: "%.2f秒", elapsedTime))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(resultColor)

            Text(resultMessage)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            Text("誤差: \(String(format: "%.2f", abs(elapsedTime - Double(targetSeconds))))秒")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

            // 速度表示
            HStack(spacing: 4) {
                Image(systemName: "speedometer")
                    .font(.system(size: 10))
                Text(currentSpeed.displayName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundColor(currentSpeed.color)

            // ランキング表示
            if let rank = currentRank {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("第\(rank)位")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                }
            }
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
        if diff < 1 { return "すばらしい！ほぼ完璧！" }
        if diff < 3 { return "いい感じ！体内時計バッチリ！" }
        if diff < 5 { return "まあまあ！もう少し！" }
        return "もう一度チャレンジ！"
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
        currentSpeed = SpeedMultiplier.random()
        gameState = .countdown
        currentRank = nil

        let countdownSequence = ["3", "2", "1", "Start!"]
        var index = 0

        // カウントダウンは通常速度（1秒間隔）
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
            // 実際の経過時間に倍速を適用（倍速が速いほど時間が速く進む）
            let actualTime = Date().timeIntervalSince(start)
            elapsedTime = actualTime * currentSpeed.rawValue
        }
        timer?.invalidate()
        timer = nil
        gameState = .result

        // スコアを保存
        let record = GameRecord(
            targetSeconds: targetSeconds,
            elapsedTime: elapsedTime,
            speedMultiplier: currentSpeed.rawValue
        )
        currentRank = rankingManager.getRank(for: record.difference)
        rankingManager.addRecord(record)
    }
}

// ランキング画面
struct RankingView: View {
    @ObservedObject var rankingManager: RankingManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.15, green: 0.1, blue: 0.25)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if rankingManager.records.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "trophy")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("まだ記録がありません")
                            .font(.system(size: 18, design: .rounded))
                            .foregroundColor(.gray)
                        Text("ゲームをプレイして\nランキングに挑戦しよう！")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(rankingManager.records.enumerated()), id: \.element.id) { index, record in
                                RankingRow(rank: index + 1, record: record)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("ランキング")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !rankingManager.records.isEmpty {
                        Button("クリア") {
                            rankingManager.clearRecords()
                        }
                        .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
            .toolbarBackground(Color(red: 0.1, green: 0.1, blue: 0.2), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// ランキング行
struct RankingRow: View {
    let rank: Int
    let record: GameRecord

    var body: some View {
        HStack(spacing: 12) {
            // 順位
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                if rank <= 3 {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(rankColor)
                        .font(.system(size: 18))
                } else {
                    Text("\(rank)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            // 記録情報
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("誤差: ")
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f秒", record.difference))
                        .foregroundColor(resultColor)
                        .fontWeight(.bold)
                }
                .font(.system(size: 15, design: .rounded))

                HStack(spacing: 8) {
                    Text("目標:\(record.targetSeconds)秒")
                    Text("実際:\(String(format: "%.1f", record.elapsedTime))秒")
                    // 速度表示
                    HStack(spacing: 2) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 9))
                        Text(record.speedDisplayName)
                    }
                    .foregroundColor(speedColor)
                }
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.gray)
            }

            Spacer()

            // 日付
            Text(formattedDate)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(rank <= 3 ? rankColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .white
        }
    }

    private var resultColor: Color {
        if record.difference < 0.5 { return .yellow }
        if record.difference < 1 { return .cyan }
        if record.difference < 3 { return .green }
        if record.difference < 5 { return .orange }
        return .pink
    }

    private var speedColor: Color {
        switch record.speedMultiplier {
        case 0.5: return .green
        case 1.0: return .cyan
        case 1.5: return .yellow
        case 2.0: return .orange
        case 3.0: return .red
        default: return .white
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        return formatter.string(from: record.date)
    }
}

#Preview {
    ContentView()
}
