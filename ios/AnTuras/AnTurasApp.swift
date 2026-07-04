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

enum Route: Hashable {
    case map
    case session(Int)
}

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var path: [Route] = []
    @State private var booted = false
    @Namespace private var zoomNS

    var body: some View {
        NavigationStack(path: $path) {
            CoverView { path.append(.map) }
                .background(Theme.bg.ignoresSafeArea())
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .tint(Theme.moss)
        .onAppear {
            guard !booted else { return }
            booted = true
            Haptics.prepare()
            // Debug deep-links for screenshots/snapshot tests: --map | --session N
            let args = ProcessInfo.processInfo.arguments
            if args.contains("--map") {
                path = [.map]
            } else if let flagIndex = args.firstIndex(of: "--session"),
                      args.indices.contains(flagIndex + 1),
                      let sessionIndex = Int(args[flagIndex + 1]),
                      state.chapter.sessions.indices.contains(sessionIndex) {
                path = [.map, .session(sessionIndex)]
            } else if state.done.contains(true) {
                path = [.map]
            }
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .map:
            MapView(zoomNS: zoomNS) { index in path.append(.session(index)) }
                .background(Theme.bg.ignoresSafeArea())
                .toolbarRole(.editor)
                .toolbarBackground(Theme.bg, for: .navigationBar)
        case .session(let index):
            SessionView(sessionIndex: index)
                .background(Theme.bg.ignoresSafeArea())
                .toolbarRole(.editor)
                .toolbarBackground(Theme.bg, for: .navigationBar)
                .zoomDestination(id: index, ns: zoomNS)
        }
    }
}

// MARK: - iOS 18 zoom transition (map waypoint → session), no-op on iOS 17.

extension View {
    @ViewBuilder
    func zoomSource(id: Int, ns: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            matchedTransitionSource(id: id, in: ns)
        } else {
            self
        }
    }

    @ViewBuilder
    func zoomDestination(id: Int, ns: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            navigationTransition(.zoom(sourceID: id, in: ns))
        } else {
            self
        }
    }
}
