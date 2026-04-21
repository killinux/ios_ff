import SwiftUI
import UIKit

struct VideoFeedView: View {
    @StateObject private var feedService = FeedService()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if feedService.isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            } else if feedService.videos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No videos")
                        .foregroundColor(.gray)
                    Button("Retry") { feedService.loadFeed() }
                        .foregroundColor(.white)
                }
            } else {
                VerticalPageView(feedService: feedService)
                    .ignoresSafeArea()
            }
        }
        .onAppear { feedService.loadFeed() }
    }
}

struct VerticalPageView: UIViewControllerRepresentable {
    @ObservedObject var feedService: FeedService

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .vertical,
            options: [.interPageSpacing: 0]
        )
        pvc.dataSource = context.coordinator
        pvc.delegate = context.coordinator
        if let first = context.coordinator.viewController(at: 0) {
            pvc.setViewControllers([first], direction: .forward, animated: false)
        }
        return pvc
    }

    func updateUIViewController(_ vc: UIPageViewController, context: Context) {
        context.coordinator.updateVideos(feedService.videos)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(feedService: feedService)
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var feedService: FeedService
        private var videos: [VideoModel]
        private var controllers: [Int: VideoPageController] = [:]
        private let log = DebugLog.shared

        init(feedService: FeedService) {
            self.feedService = feedService
            self.videos = feedService.videos
        }

        func updateVideos(_ newVideos: [VideoModel]) {
            self.videos = newVideos
        }

        func viewController(at index: Int) -> VideoPageController? {
            guard index >= 0, index < videos.count else { return nil }
            if let existing = controllers[index] { return existing }
            let vc = VideoPageController()
            vc.video = videos[index]
            vc.pageIndex = index
            controllers[index] = vc
            return vc
        }

        func pageViewController(_ pvc: UIPageViewController, viewControllerBefore vc: UIViewController) -> UIViewController? {
            guard let vc = vc as? VideoPageController else { return nil }
            return viewController(at: vc.pageIndex - 1)
        }

        func pageViewController(_ pvc: UIPageViewController, viewControllerAfter vc: UIViewController) -> UIViewController? {
            guard let vc = vc as? VideoPageController else { return nil }
            let nextIndex = vc.pageIndex + 1
            feedService.loadMoreIfNeeded(currentIndex: vc.pageIndex)
            return viewController(at: nextIndex)
        }

        func pageViewController(_ pvc: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            guard completed else { return }
            for prev in previousViewControllers {
                if let p = prev as? VideoPageController {
                    p.pause()
                }
            }
            if let current = pvc.viewControllers?.first as? VideoPageController {
                let video = current.video!
                log.log("Swipe -> index \(current.pageIndex), \(video.author)", type: .swipe)
                log.log("Play: \(video.videoUrl.components(separatedBy: "/").last ?? "")", type: .play)
                current.play()
            }
        }
    }
}

class VideoPageController: UIViewController {
    var video: VideoModel!
    var pageIndex: Int = 0
    private var playerView: PlayerUIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        guard let url = video.url else { return }

        let pv = PlayerUIView(frame: view.bounds)
        pv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pv.configure(url: url)
        view.addSubview(pv)
        self.playerView = pv

        let overlay = UIHostingController(rootView: VideoOverlayView(video: video))
        overlay.view.backgroundColor = .clear
        overlay.view.frame = view.bounds
        overlay.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addChild(overlay)
        view.addSubview(overlay.view)
        overlay.didMove(toParent: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        play()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pause()
    }

    func play() { playerView?.play() }
    func pause() { playerView?.pause() }
}
