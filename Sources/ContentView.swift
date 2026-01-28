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
    let userName: String
    let targetSeconds: Int
    let elapsedTime: Double
    let difference: Double
    let speedMultiplier: Double
    let date: Date

    init(userName: String, targetSeconds: Int, elapsedTime: Double, speedMultiplier: Double = 1.0) {
        self.id = UUID()
        self.userName = userName
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
    private let key = "gameRecords_v3"

    init() {
        loadRecords()
    }

    func addRecord(_ record: GameRecord) {
        records.append(record)
        records.sort { $0.difference < $1.difference }
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

// 踊るおじさんアニメーション（拡張版）
struct DancingManView: View {
    @State private var isAnimating = false
    @State private var bounceOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var horizontalOffset: CGFloat = 0
    @State private var colorHue: Double = 0
    @State private var currentEmojiIndex = 0
    @State private var currentMessageIndex = 0
    @State private var showSparkle = false
    @State private var sparkleRotation: Double = 0

    let emojis = ["🕺", "💃", "🧍", "🏃", "🚶", "🤸", "🧘", "🏋️", "⛹️", "🤾", "🎭", "🎪", "🎉", "🌟", "🔥"]

    let messages = [
        "♪ ノリノリ〜 ♪",
        "集中！集中！",
        "いい感じ〜",
        "まだかな？",
        "ダンス！ダンス！",
        "イェーイ！",
        "ファイト！",
        "もうすぐ？",
        "踊れ踊れ〜",
        "🎵 ズンチャ！",
        "ほらほら〜",
        "ボタン押して！",
        "逃がさないよ！"
    ]

    var body: some View {
        ZStack {
            // キラキラエフェクト
            ForEach(0..<5) { i in
                Text("✨")
                    .font(.system(size: 20))
                    .offset(
                        x: CGFloat.random(in: -60...60),
                        y: CGFloat.random(in: -60...60)
                    )
                    .opacity(showSparkle ? 1 : 0)
                    .rotationEffect(.degrees(sparkleRotation + Double(i * 72)))
            }

            VStack(spacing: 8) {
                // 踊るキャラクター
                Text(emojis[currentEmojiIndex])
                    .font(.system(size: 70))
                    .rotationEffect(.degrees(rotation))
                    .offset(x: horizontalOffset, y: bounceOffset)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .hueRotation(Angle(degrees: colorHue))

                // メッセージ
                Text(messages[currentMessageIndex])
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.purple.opacity(0.6))
                    )
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
            }
        }
        .onAppear {
            startDancing()
        }
    }

    private func startDancing() {
        // バウンスアニメーション
        withAnimation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true)) {
            bounceOffset = -15
        }

        // 回転アニメーション
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            rotation = 15
        }

        // 横移動アニメーション
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            horizontalOffset = 20
        }

        // スケールアニメーション
        withAnimation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true)) {
            isAnimating = true
        }

        // 色相アニメーション
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            colorHue = 360
        }

        // キラキラアニメーション
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            showSparkle = true
        }

        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            sparkleRotation = 360
        }

        // 絵文字切り替え
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                currentEmojiIndex = Int.random(in: 0..<emojis.count)
            }
        }

        // メッセージ切り替え
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                currentMessageIndex = Int.random(in: 0..<messages.count)
            }
        }
    }
}

// 逃げ回るストップボタン
struct RunawayStopButton: View {
    let action: () -> Void
    @State private var buttonOffset: CGSize = .zero
    @State private var buttonRotation: Double = 0
    @State private var buttonScale: CGFloat = 1.0
    @State private var moveTimer: Timer?

    var body: some View {
        GeometryReader { geometry in
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Stop")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(width: 160, height: 55)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.pink, Color.red]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.red.opacity(0.5), radius: 10, y: 5)
                .rotationEffect(.degrees(buttonRotation))
                .scaleEffect(buttonScale)
            }
            .position(
                x: geometry.size.width / 2 + buttonOffset.width,
                y: geometry.size.height / 2 + buttonOffset.height
            )
            .onAppear {
                startRunning(in: geometry.size)
            }
            .onDisappear {
                moveTimer?.invalidate()
            }
        }
        .frame(height: 120)
    }

    private func startRunning(in size: CGSize) {
        // ランダム移動タイマー
        moveTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            let maxX = (size.width / 2) - 90
            let maxY: CGFloat = 25

            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                buttonOffset = CGSize(
                    width: CGFloat.random(in: -maxX...maxX),
                    height: CGFloat.random(in: -maxY...maxY)
                )
                buttonRotation = Double.random(in: -15...15)
                buttonScale = CGFloat.random(in: 0.9...1.1)
            }
        }

        // 初期移動
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let maxX = (size.width / 2) - 90
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                buttonOffset = CGSize(
                    width: CGFloat.random(in: -maxX...maxX),
                    height: CGFloat.random(in: -25...25)
                )
            }
        }
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
    @State private var userName: String = ""
    @StateObject private var rankingManager = RankingManager()

    private let userNameKey = "savedUserName"

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

            VStack(spacing: 16) {
                // ヘッダー
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

                // ユーザー名入力
                if gameState == .idle {
                    userNameInputView
                }

                Spacer()

                // メイン表示エリア
                mainDisplayArea

                Spacer()

                // ターゲット時間と速度表示
                if gameState != .idle {
                    VStack(spacing: 10) {
                        targetTimeView
                        speedIndicatorView
                    }
                }

                // ボタンエリア
                if gameState == .running {
                    // 逃げ回るストップボタン
                    RunawayStopButton(action: stopGame)
                } else {
                    // 通常ボタン
                    actionButton
                        .frame(height: 120)
                }

                Spacer()
                    .frame(height: 20)
            }
            .padding()
        }
        .sheet(isPresented: $showRanking) {
            RankingView(rankingManager: rankingManager)
        }
        .onAppear {
            userName = UserDefaults.standard.string(forKey: userNameKey) ?? ""
        }
    }

    private var userNameInputView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .foregroundColor(.cyan)
                Text("プレイヤー名")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }

            TextField("名前を入力", text: $userName)
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                        )
                )
                .frame(maxWidth: 250)
                .onChange(of: userName) { _, newValue in
                    UserDefaults.standard.set(newValue, forKey: userNameKey)
                }
        }
    }

    @ViewBuilder
    private var mainDisplayArea: some View {
        ZStack {
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
                DancingManView()

            case .result:
                resultView
            }
        }
    }

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

            HStack(spacing: 4) {
                Image(systemName: "speedometer")
                    .font(.system(size: 10))
                Text(currentSpeed.displayName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundColor(currentSpeed.color)

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
                    gradient: Gradient(colors: [Color.cyan, Color.blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color.cyan.opacity(0.5), radius: 10, y: 5)
        }
        .disabled(gameState == .countdown || (gameState == .idle && userName.trimmingCharacters(in: .whitespaces).isEmpty))
        .opacity((gameState == .countdown || (gameState == .idle && userName.trimmingCharacters(in: .whitespaces).isEmpty)) ? 0.5 : 1)
    }

    private var buttonText: String {
        switch gameState {
        case .idle:
            return userName.trimmingCharacters(in: .whitespaces).isEmpty ? "名前を入力" : "Start"
        case .result: return "Start"
        case .countdown: return "..."
        case .running: return "Stop"
        }
    }

    private var buttonIcon: String {
        switch gameState {
        case .idle, .result: return "play.fill"
        case .countdown: return "hourglass"
        case .running: return "stop.fill"
        }
    }

    private var resultEmoji: String {
        let diff = abs(elapsedTime - Double(targetSeconds))
        if diff < 0.5 { return "🎯" }
        if diff < 1 { return "🌟" }
        if diff < 3 { return "👏" }
        if diff < 5 { return "👍" }
        return "💪"
    }

    private var resultMessage: String {
        let diff = abs(elapsedTime - Double(targetSeconds))
        if diff < 0.5 { return "完璧！神業です！" }
        if diff < 1 { return "すばらしい！ほぼ完璧！" }
        if diff < 3 { return "いい感じ！体内時計バッチリ！" }
        if diff < 5 { return "まあまあ！もう少し！" }
        return "もう一度チャレンジ！"
    }

    private var resultColor: Color {
        let diff = abs(elapsedTime - Double(targetSeconds))
        if diff < 0.5 { return .yellow }
        if diff < 1 { return .cyan }
        if diff < 3 { return .green }
        if diff < 5 { return .orange }
        return .pink
    }

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

    private func startGame() {
        targetSeconds = Int.random(in: 1...60)
        currentSpeed = SpeedMultiplier.random()
        gameState = .countdown
        currentRank = nil

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

    private func startTimer() {
        gameState = .running
        startTime = Date()
    }

    private func stopGame() {
        if let start = startTime {
            let actualTime = Date().timeIntervalSince(start)
            elapsedTime = actualTime * currentSpeed.rawValue
        }
        timer?.invalidate()
        timer = nil
        gameState = .result

        let displayName = userName.trimmingCharacters(in: .whitespaces).isEmpty ? "ゲスト" : userName
        let record = GameRecord(
            userName: displayName,
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

struct RankingRow: View {
    let rank: Int
    let record: GameRecord

    var body: some View {
        HStack(spacing: 12) {
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

            VStack(alignment: .leading, spacing: 4) {
                Text(record.userName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                HStack {
                    Text("誤差: ")
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f秒", record.difference))
                        .foregroundColor(resultColor)
                        .fontWeight(.bold)
                }
                .font(.system(size: 13, design: .rounded))

                HStack(spacing: 6) {
                    Text("目標:\(record.targetSeconds)秒")
                    HStack(spacing: 2) {
                        Image(systemName: "hare.fill")
                            .font(.system(size: 8))
                        Text(record.speedDisplayName)
                    }
                    .foregroundColor(speedColor)
                }
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.gray)
            }

            Spacer()

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
