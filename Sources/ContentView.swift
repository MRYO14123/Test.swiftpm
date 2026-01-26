import SwiftUI

struct ContentView: View {
    @State private var diceHistory: [Int] = []

    var body: some View {
        VStack {
            Spacer()

            // 履歴表示（上に行くほど薄く）
            if diceHistory.count > 1 {
                VStack(spacing: 8) {
                    ForEach(Array(diceHistory.dropLast().reversed().enumerated()), id: \.offset) { index, number in
                        Text("\(number)")
                            .font(.system(size: 40, weight: .bold))
                            .opacity(calculateOpacity(index: index, total: diceHistory.count - 1))
                    }
                }
            }

            // 現在の数字（画面中央）
            if let currentNumber = diceHistory.last {
                Text("\(currentNumber)")
                    .font(.system(size: 100, weight: .bold))
                    .padding(.vertical, 20)
            }

            Spacer()

            // ダイスを振るボタン（画面下部）
            Button("ダイスを振る") {
                let newNumber = Int.random(in: 1...6)
                diceHistory.append(newNumber)
            }
            .font(.title2)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.bottom, 40)
        }
    }

    private func calculateOpacity(index: Int, total: Int) -> Double {
        guard total > 0 else { return 1.0 }
        // index 0 が最新の履歴（一番濃い）、上に行くほど薄くなる
        let maxOpacity = 0.7
        let minOpacity = 0.1
        let step = (maxOpacity - minOpacity) / max(Double(total - 1), 1.0)
        return max(maxOpacity - step * Double(index), minOpacity)
    }
}

#Preview {
    ContentView()
}
