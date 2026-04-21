# ios_ff

一个类似抖音/TikTok 的 iOS 短视频应用，配合后端 Feed 服务实现视频流播放。

## 架构

```
┌──────────────┐         ┌──────────────────────┐
│   iOS App    │  HTTP   │   Feed Server        │
│  (SwiftUI)   │◄───────►│  (Python, 腾讯云)     │
│              │         │                      │
│  AVPlayer    │  Range  │  /api/feed?page=N    │
│  UIPageVC    │◄───────►│  /videos/*.mp4       │
└──────────────┘         └──────────────────────┘
```

## 技术栈

### iOS 客户端 (`ios_ff/`)

- **SwiftUI** — UI 框架，Tab 栏、Overlay 按钮、Debug 页面
- **UIPageViewController** — 垂直翻页控制器，实现上下滑动切换视频，每页精准对齐
- **AVQueuePlayer + AVPlayerLooper** — 视频播放与无缝循环，通过 AVPlayerLayer 渲染到全屏
- **UIViewControllerRepresentable** — UIKit 与 SwiftUI 桥接
- **URLSession** — 网络请求，拉取 Feed API
- **Combine** — 数据绑定（@Published / @ObservedObject）

### 后端服务 (`server/`)

- **Python http.server** — 轻量 HTTP 服务，无第三方依赖
- **分页 API** — `GET /api/feed?page=N`，每页 5 条，15 条循环
- **视频流** — 支持 HEAD 请求（AVPlayer 探测）和 Range 请求（206 Partial Content，流式加载）
- **ThreadingHTTPServer** — 多线程处理并发请求

## 功能

### 已实现

- ✅ 全屏竖屏视频流，上下滑动切换
- ✅ 视频自动循环播放（AVPlayerLooper）
- ✅ 滑动切换时自动播放/暂停
- ✅ 右侧互动按钮（点赞/评论/分享/收藏），点赞可点亮红心
- ✅ 底部作者名、描述、音乐名
- ✅ 底部 Tab 栏（Home / Discover / + / Inbox / Me）
- ✅ 抖音风格渐变 "+" 按钮
- ✅ 分页加载：每次 5 个视频，滑到第 4 个时后台预加载下一页
- ✅ 无限滚动：15 条内容循环，8 个视频文件轮转
- ✅ Debug 日志页（Discover Tab）：记录 Feed 请求、滑动事件、播放状态
- ✅ HTTP 允许（Info.plist ATS 配置）

### 待实现

- 拍摄/上传视频
- 评论/分享实际功能
- 用户系统/登录
- 视频缓存/预加载优化
- 主题/字体设置

## 运行

### 服务端（腾讯云或任意 Linux）

```bash
cd server
# 放视频文件到 videos/ 目录
bash start.sh
# 服务运行在 0.0.0.0:8085
```

API 示例：
```bash
curl http://<server-ip>:8085/api/feed?page=0
curl http://<server-ip>:8085/health
```

### iOS 客户端

1. 修改 `ios_ff/Models/VideoModel.swift` 中的 `baseURL` 为你的服务器地址
2. Xcode 打开 `ios_ff.xcodeproj`
3. 选择模拟器或真机，Run

## 项目结构

```
ios_ff/
├── Info.plist                    # ATS 配置，允许 HTTP
├── ios_ff.xcodeproj/
├── ios_ff/
│   ├── ios_ffApp.swift           # App 入口
│   ├── ContentView.swift         # 根视图 + Tab 栏 + Debug 日志页
│   ├── Models/
│   │   └── VideoModel.swift      # 数据模型 + FeedService（分页加载）
│   ├── Players/
│   │   └── PlayerView.swift      # AVPlayer UIView 封装
│   └── Views/
│       ├── VideoFeedView.swift   # UIPageViewController 垂直翻页 + 预加载
│       └── VideoOverlayView.swift # 右侧按钮 + 底部信息 Overlay
├── server/
│   ├── feed_server.py            # Feed API + 视频文件服务
│   ├── start.sh                  # 启动脚本
│   └── videos/                   # 视频文件（不提交到 git）
└── .gitignore
```
