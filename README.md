# OmniStream & MediaHub (iOS 16 - 18+)

> **Native iOS Media Pipeline & Transcoder with Liquid Glass Design System**  
> Tối ưu hiển thị hoàn hảo từ màn hình tai thỏ (iPhone X, XS, 11) đến Dynamic Island (iPhone 14 Pro, 15 Pro, 16 Pro Max).

---

## 🌟 Tính Năng Nổi Bật

### 1. Giao Diện Liquid Glass (Modern Glassmorphism)
- **Vật liệu kính siêu mỏng (`.ultraThinMaterial`)**: Tạo cảm giác khúc xạ ánh sáng chân thực.
- **Viền phản quang vi mô (`strokeBorder(LinearGradient)`)**: Mô phỏng góc vát phản xạ ánh sáng của kính sapphire.
- **Dynamic Fluid Ambient Background**: Tích hợp **MeshGradient native trên iOS 18+** và bộ chuyển màu Radial/Angular Gradient chuyển động mượt mà trên iOS 16-17.
- **Phản hồi xúc giác (Haptic Feedback)**: Tích hợp `UIImpactFeedbackGenerator` (.rigid, .medium, .soft) trên mọi nút bấm và thanh trượt.
- **Tương thích toàn diện**: Sử dụng `.safeAreaInset()` và padding thích ứng, hiển thị hoàn hảo từ iPhone X (5.8") đến iPhone 16 Pro Max (6.9").
- **Smart Clipboard Detection**: Tự động phát hiện liên kết trong bộ nhớ tạm khi mở app, phân tích metadata và hiển thị preview thumbnail trước khi tải.

### 2. Media Engine & Transcoder Ngoại Tuyến (Offline Transcoding)
- **Download Pipeline**: Xây dựng trên `URLSessionDownloadDelegate` kết hợp `URLSessionConfiguration.background`, hỗ trợ tải nền khi app bị minimize, tự động tính tốc độ (MB/s), thời gian còn lại (ETA) và quản lý `resumeData`.
- **Tách âm thanh từ video (Audio Extraction)**: 
  - Sử dụng `AVAssetReader` & `AVAssetWriter` và `AVAssetExportSession`.
  - Hỗ trợ xuất: **M4A / AAC / WAV (Linear PCM nguyên bản) / MP3**.
  - Tùy chỉnh chất lượng Bitrate: **128 kbps (Tiết kiệm)**, **192 kbps (Chuẩn HQ)**, **320 kbps (Audiophile)**.
- **Nén & Chuyển đổi Video**:
  - Hỗ trợ chuẩn nén tiên tiến **HEVC (H.265)** và tương thích cao **H.264 (AVC)**.
  - Các mức độ phân giải mục tiêu: 1080p (Full HD), 720p (HD), 480p (SD).

### 3. Tích Hợp Files App & Photos Framework
- **Quản lý Documents**: Kích hoạt `UIFileSharingEnabled = YES` và `LSSupportsOpeningDocumentsInPlace = YES`, cho phép truy cập, sao chép file trực tiếp từ ứng dụng **Files (Tệp)** của iOS.
- **Photos Framework (`PHPhotoLibrary`)**: Tự động xin quyền và lưu video đã tải hoặc đã chuyển đổi trực tiếp vào Cuộn Camera (Camera Roll).
- **Trình phát tích hợp Mini Player & Full Player**: Sử dụng `AVPlayer`, hỗ trợ scrub thời gian, tua 15s, phát nền (`UIBackgroundModes: audio`).
- **Phân loại thẻ (Tags)**: Gán nhãn `#Video`, `#Audio`, `#Yêu thích`, `#Công việc`, `#Đã chuyển đổi`.

---

## 🛠️ Cấu Trúc Thư Mục (MVVM Architecture)

```
OmniStream/
├── .github/
│   └── workflows/
│       └── build.yml               # CI/CD GitHub Actions xcodebuild IPA Unsigned
├── project.yml                     # Cấu hình dự án XcodeGen
├── OmniStream/
│   ├── App/
│   │   ├── OmniStreamApp.swift     # Entry point SwiftUI
│   │   ├── AppDelegate.swift       # Xử lý background URLSession completion
│   │   └── Info.plist              # Quyền Photos, Files sharing, Background modes
│   ├── DesignSystem/
│   │   ├── LiquidGlass.swift       # Modifiers kính mờ, viền khúc xạ & đổ bóng
│   │   ├── LiquidBackground.swift  # MeshGradient (iOS 18) & dynamic ambient
│   │   ├── GlassComponents.swift   # GlassCard, GlassButton, GlassTextField, GlassProgressBar
│   │   └── HapticFeedback.swift    # Phản hồi xúc giác UIImpactFeedbackGenerator
│   ├── Models/
│   │   ├── MediaItem.swift         # Quản lý tệp cục bộ và metadata
│   │   ├── DownloadTaskItem.swift  # Trạng thái tải nền, tốc độ, ETA
│   │   ├── ConversionPreset.swift  # Cấu hình âm thanh (bitrate) & video (codec)
│   │   └── MediaTag.swift          # Danh mục phân loại thẻ
│   ├── Services/
│   │   ├── DownloadManager.swift   # URLSessionDownloadDelegate ngầm
│   │   ├── MediaConverterService.swift # AVAsset/AVAssetWriter offline transcoder
│   │   ├── StorageManager.swift    # Quản lý thư mục sandbox Documents
│   │   ├── PhotoLibraryManager.swift # Lưu video vào Camera Roll
│   │   └── MetadataExtractor.swift # Quét HEAD lấy thumbnail, mime, size
│   ├── ViewModels/
│   │   ├── DashboardViewModel.swift
│   │   ├── ConverterViewModel.swift
│   │   ├── LibraryViewModel.swift
│   │   └── PlayerViewModel.swift
│   └── Views/
│       ├── MainTabView.swift       # Tab Bar kính nổi + Mini Player
│       ├── Dashboard/              # Trình tải xuống & phát hiện clipboard
│       ├── Converter/              # Studio tách âm thanh và nén video
│       ├── Library/                # Kho lưu trữ, bộ lọc tags & chia sẻ
│       └── Player/                 # Mini Player & Full-screen Player
└── README.md
```

---

## 🚀 Hướng Dẫn Biên Dịch & Đóng Gói (Build & Sideload)

### Cách 1: Sử dụng XcodeGen trên máy Mac
1. Cài đặt **XcodeGen** (nếu chưa có):
   ```bash
   brew install xcodegen
   ```
2. Di chuyển vào thư mục dự án và sinh file `.xcodeproj`:
   ```bash
   cd OmniStream
   xcodegen generate
   ```
3. Mở `OmniStream.xcodeproj` bằng Xcode 15 hoặc 16 và nhấn `Cmd + R` để chạy trên Simulator hoặc iPhone thật.

---

### Cách 2: Tự động Build IPA Unsigned qua GitHub Actions
Dự án đã được tích hợp sẵn workflow `.github/workflows/build.yml`:
1. Push mã nguồn lên GitHub repository cá nhân.
2. Vào tab **Actions** -> Chọn workflow **Build Unsigned IPA for Sideloading** -> Nhấn **Run workflow**.
3. Sau khi hoàn tất (khoảng 2-3 phút), tải file `OmniStream-Unsigned.ipa` trong mục **Artifacts**.

---

## 📲 Hướng Dẫn Cài Đặt Sideload

File `.ipa` xuất ra ở chế độ Unsigned nên sẵn sàng để cài đặt qua mọi công cụ phổ biến:

| Công cụ Sideload | Phương thức | Ưu điểm |
|---|---|---|
| **TrollStore** | Cài trực tiếp file `.ipa` | Vĩnh viễn không bị thu hồi chứng chỉ (Revoke), full entitlements |
| **AltStore / SideStore** | Cài qua Apple ID cá nhân | Tự động làm mới chứng chỉ qua Wi-Fi |
| **Scarlet / Esign** | Ký bằng chứng chỉ doanh nghiệp | Cài đặt trực tiếp trên iPhone không cần máy tính |

---

## 📄 Bản Quyền & Giấy Phép
Dự án được xây dựng phục vụ cộng đồng đam mê iOS và âm nhạc chất lượng cao.
Phát triển với triết lý kiến trúc sạch (Clean Architecture) và trải nghiệm người dùng tinh tế.
