import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                VideoFeedView()
                    .tag(0)
                PlaceholderView(title: "Discover")
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
