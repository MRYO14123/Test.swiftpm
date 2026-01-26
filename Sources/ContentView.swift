import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Button("OK") {
                print("OK button tapped")
            }
            .font(.title)
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
