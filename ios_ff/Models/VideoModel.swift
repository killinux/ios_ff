import Combine
import Foundation

struct VideoModel: Identifiable, Codable {
    let id: String
    let author: String
    let description: String
    let likes: Int
    let comments: Int
    let shares: Int
    let musicName: String
    let videoUrl: String

    var url: URL? { URL(string: videoUrl) }
    var authorAvatar: String { "person.circle.fill" }
}

struct FeedResponse: Codable {
    let videos: [VideoModel]
    let page: Int
    let hasMore: Bool
}

class FeedService: ObservableObject {
    static let baseURL = "http://49.233.189.223:8085"

    @Published var videos: [VideoModel] = []
    @Published var isLoading = false
    private var currentPage = 0
    private var isFetching = false
    private var hasMore = true
    private let log = DebugLog.shared

    func loadFeed() {
        currentPage = 0
        hasMore = true
        videos = []
        log.log("Initial feed load", type: .feed)
        fetchPage(page: 0)
    }

    func loadMoreIfNeeded(currentIndex: Int) {
        let threshold = videos.count - 2
        if currentIndex >= threshold && hasMore && !isFetching {
            log.log("Prefetch triggered at index \(currentIndex)/\(videos.count), loading page \(currentPage + 1)", type: .feed)
            fetchPage(page: currentPage + 1)
        }
    }

    private func fetchPage(page: Int) {
        let urlStr = "\(Self.baseURL)/api/feed?page=\(page)"
        guard let url = URL(string: urlStr) else { return }
        isFetching = true
        if page == 0 { isLoading = true }

        log.log("GET \(urlStr)", type: .feed)
        let startTime = Date()

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            let elapsed = String(format: "%.0fms", Date().timeIntervalSince(startTime) * 1000)

            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isFetching = false
                self.isLoading = false

                if let error = error {
                    self.log.log("Feed error: \(error.localizedDescription) (\(elapsed))", type: .error)
                    return
                }

                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

                guard let data = data,
                      let resp = try? JSONDecoder().decode(FeedResponse.self, from: data) else {
                    self.log.log("Feed decode failed, status=\(statusCode) (\(elapsed))", type: .error)
                    return
                }

                self.currentPage = resp.page
                self.hasMore = resp.hasMore
                let prevCount = self.videos.count
                if page == 0 {
                    self.videos = resp.videos
                } else {
                    self.videos.append(contentsOf: resp.videos)
                }
                self.log.log("Page \(page) OK: +\(resp.videos.count) videos, total=\(self.videos.count) (\(elapsed))", type: .feed)
            }
        }.resume()
    }
}
