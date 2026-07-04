import SwiftUI

@main
struct AnTurasApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
        }
    }
}

enum Screen: Equatable {
    case cover
    case map
    case session(Int)
}

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var screen: Screen = .cover
    @State private var booted = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch screen {
            case .cover:
                CoverView { withAnimation(.easeInOut) { screen = .map } }
            case .map:
                MapView { index in withAnimation(.easeInOut) { screen = .session(index) } }
            case .session(let index):
                SessionView(sessionIndex: index) {
                    withAnimation(.easeInOut) { screen = .map }
                }
                .id(index)
            }
        }
        .tint(Theme.moss)
        .onAppear {
            guard !booted else { return }
            booted = true
            // Debug deep-links for screenshots/snapshot tests: --map | --session N
            let args = ProcessInfo.processInfo.arguments
            if args.contains("--map") {
                screen = .map
            } else if let flagIndex = args.firstIndex(of: "--session"),
                      args.indices.contains(flagIndex + 1),
                      let sessionIndex = Int(args[flagIndex + 1]),
                      state.chapter.sessions.indices.contains(sessionIndex) {
                screen = .session(sessionIndex)
            } else if state.done.contains(true) {
                screen = .map
            }
        }
    }
}
