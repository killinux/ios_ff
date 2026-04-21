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
}

class FeedService: ObservableObject {
    static let baseURL = "http://49.233.189.223:8085"

    @Published var videos: [VideoModel] = []
    @Published var isLoading = false

    func loadFeed() {
        guard let url = URL(string: "\(Self.baseURL)/api/feed") else { return }
        isLoading = true
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let data = data, error == nil else { return }
                if let resp = try? JSONDecoder().decode(FeedResponse.self, from: data) {
                    self?.videos = resp.videos
                }
            }
        }.resume()
    }
}
