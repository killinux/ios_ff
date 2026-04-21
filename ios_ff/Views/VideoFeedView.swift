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
                VerticalPageView(videos: feedService.videos)
                    .ignoresSafeArea()
            }
        }
        .onAppear { feedService.loadFeed() }
    }
}

struct VerticalPageView: UIViewControllerRepresentable {
    let videos: [VideoModel]

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

    func updateUIViewController(_ vc: UIPageViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(videos: videos)
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        let videos: [VideoModel]
        private var controllers: [Int: VideoPageController] = [:]

        init(videos: [VideoModel]) {
            self.videos = videos
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
            return viewController(at: vc.pageIndex + 1)
        }

        func pageViewController(_ pvc: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            guard completed else { return }
            for prev in previousViewControllers {
                (prev as? VideoPageController)?.pause()
            }
            if let current = pvc.viewControllers?.first as? VideoPageController {
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
