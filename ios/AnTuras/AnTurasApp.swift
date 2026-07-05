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
    case journey
    case map
    case session(Int)
    case museum
    case arAis
}

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var path: [Route] = []
    @State private var booted = false
    @Namespace private var zoomNS

    var body: some View {
        NavigationStack(path: $path) {
            CoverView { path.append(.journey) }
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
            // Debug deep-links for screenshots/snapshot tests:
            // --journey | --map | --session N | --museum | --arais
            let args = ProcessInfo.processInfo.arguments
            if args.contains("--journey") {
                path = [.journey]
            } else if args.contains("--museum") {
                path = [.journey, .museum]
            } else if args.contains("--arais") {
                path = [.journey, .arAis]
            } else if args.contains("--map") {
                path = [.journey, .map]
            } else if let flagIndex = args.firstIndex(of: "--session"),
                      args.indices.contains(flagIndex + 1),
                      let sessionIndex = Int(args[flagIndex + 1]),
                      state.chapter.sessions.indices.contains(sessionIndex) {
                path = [.journey, .map, .session(sessionIndex)]
            } else if state.done.contains(true) {
                // Returning learners land on the journey when someone is
                // asking for them (Ar Ais owns the welcome), otherwise one
                // step from the work, with the island a back-swipe away.
                path = state.dueVisits().isEmpty ? [.journey, .map] : [.journey]
            }
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .journey:
            JourneyView(
                onOpenChapter: { path.append(.map) },
                onOpenMuseum: { path.append(.museum) },
                onOpenArAis: { path.append(.arAis) })
                .background(Theme.bg.ignoresSafeArea())
                .toolbarRole(.editor)
                .toolbarBackground(Theme.bg, for: .navigationBar)
        case .map:
            MapView(zoomNS: zoomNS,
                    onOpenSession: { index in path.append(.session(index)) },
                    onOpenMuseum: { path.append(.museum) })
                .background(Theme.bg.ignoresSafeArea())
                .toolbarRole(.editor)
                .toolbarBackground(Theme.bg, for: .navigationBar)
        case .session(let index):
            SessionView(sessionIndex: index)
                .background(Theme.bg.ignoresSafeArea())
                .toolbarRole(.editor)
                .toolbarBackground(Theme.bg, for: .navigationBar)
                .zoomDestination(id: index, ns: zoomNS)
        case .museum:
            MuseumView(onOpenArAis: { path.append(.arAis) },
                       onOpenChapter: { path.append(.map) })
                .background(Theme.bg.ignoresSafeArea())
                .toolbarRole(.editor)
                .toolbarBackground(Theme.bg, for: .navigationBar)
        case .arAis:
            ArAisView()
                .background(Theme.bg.ignoresSafeArea())
                .toolbarRole(.editor)
                .toolbarBackground(Theme.bg, for: .navigationBar)
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
