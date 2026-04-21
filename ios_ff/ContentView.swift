import Combine
import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var debugLog = DebugLog.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                VideoFeedView()
                    .tag(0)
                DebugLogView()
                    .tag(1)
                PlaceholderView(title: "")
                    .tag(2)
                PlaceholderView(title: "Inbox")
                    .tag(3)
                PlaceholderView(title: "Profile")
                    .tag(4)
            }

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct PlaceholderView: View {
    let title: String
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text(title)
                .font(.title)
                .foregroundColor(.white)
        }
    }
}

struct DebugLogView: View {
    @ObservedObject var log = DebugLog.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Debug Log")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(log.entries.count) entries")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button("Clear") { log.clear() }
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)
                .padding(.bottom, 8)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(log.entries) { entry in
                                HStack(alignment: .top, spacing: 6) {
                                    Text(entry.time)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.gray)
                                    Text(entry.icon)
                                        .font(.system(size: 10))
                                    Text(entry.message)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(entry.color)
                                }
                                .id(entry.id)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .onChange(of: log.entries.count) {
                        if let last = log.entries.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }

                Spacer().frame(height: 80)
            }
        }
    }
}

class DebugLog: ObservableObject {
    static let shared = DebugLog()

    struct Entry: Identifiable {
        let id = UUID()
        let time: String
        let icon: String
        let message: String
        let type: LogType
        var color: Color {
            switch type {
            case .feed: return .cyan
            case .swipe: return .yellow
            case .play: return .green
            case .error: return .red
            case .info: return .white
            }
        }
    }

    enum LogType { case feed, swipe, play, error, info }

    @Published var entries: [Entry] = []
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    func log(_ message: String, type: LogType) {
        let entry = Entry(
            time: formatter.string(from: Date()),
            icon: iconFor(type),
            message: message,
            type: type
        )
        DispatchQueue.main.async {
            self.entries.append(entry)
            if self.entries.count > 500 {
                self.entries.removeFirst(self.entries.count - 500)
            }
        }
    }

    func clear() { entries.removeAll() }

    private func iconFor(_ type: LogType) -> String {
        switch type {
        case .feed: return "📡"
        case .swipe: return "👆"
        case .play: return "▶️"
        case .error: return "❌"
        case .info: return "ℹ️"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack {
            tabItem(icon: "house.fill", label: "Home", index: 0)
            Spacer()
            tabItem(icon: "safari", label: "Discover", index: 1)
            Spacer()
            createButton
            Spacer()
            tabItem(icon: "message", label: "Inbox", index: 3)
            Spacer()
            tabItem(icon: "person", label: "Me", index: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .background(
            Color.black.opacity(0.9)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabItem(icon: String, label: String, index: Int) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundColor(selectedTab == index ? .white : .gray)
        }
    }

    private var createButton: some View {
        Button {
            selectedTab = 2
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 48, height: 30)
                RoundedRectangle(cornerRadius: 7)
                    .fill(.white)
                    .frame(width: 40, height: 26)
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }
        }
    }
}

#Preview {
    ContentView()
}
