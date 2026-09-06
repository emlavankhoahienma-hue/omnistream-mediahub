import SwiftUI

// MARK: - Converter View
public struct ConverterView: View {
    @StateObject private var viewModel = ConverterViewModel()
    @State private var showFilePickerSheet = false
    @State private var availableItems: [MediaItem] = []
    @Namespace private var modeNamespace

    public init() {}

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Header Bar
                headerBar
                    .padding(.top, 10)

                // Mode Selector
                modeSelector

                // Media Source Selection Card
                sourceMediaCard

                // Configuration Card with Fluid Transition
                ZStack {
                    if viewModel.selectedMode == .audio {
                        AudioExtractionCard(
                            selectedFormat: $viewModel.selectedAudioFormat,
                            selectedBitrate: $viewModel.selectedAudioBitrate
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 10)),
                            removal: .opacity
                        ))
                    } else {
                        VideoCompressionCard(
                            selectedCodec: $viewModel.selectedVideoCodec,
                            selectedQuality: $viewModel.selectedVideoQuality
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 10)),
                            removal: .opacity
                        ))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.selectedMode)

                // Tiến trình đang xử lý
                if viewModel.isTranscoding {
                    transcodingProgressCard
                } else {
                    // Nút hành động chính
                    GlassButton(
                        viewModel.selectedMode == .audio ? "Bắt Đầu Tách Âm Thanh" : "Bắt Đầu Nén Video",
                        icon: "bolt.fill",
                        style: .vibrantGradient
                    ) {
                        viewModel.startConversion()
                    }
                    .disabled(viewModel.selectedMediaItem == nil)
                    .opacity(viewModel.selectedMediaItem == nil ? 0.6 : 1.0)
                }

                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, 18)
        }
        .sheet(isPresented: $showFilePickerSheet) {
            filePickerModal
        }
        .alert("Thông Báo", isPresented: $viewModel.showErrorAlert) {
            Button("Đóng", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $viewModel.showSuccessSheet) {
            successModal
        }
        .onAppear {
            loadAvailableVideos()
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Transcode Studio")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.primary, .pink], startPoint: .leading, endPoint: .trailing)
                    )

                Text("Xử lý đa phương tiện ngoại tuyến")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Mode Selector with Sliding Liquid Glass Pill
    private var modeSelector: some View {
        HStack(spacing: 8) {
            ForEach(ConverterMode.allCases) { mode in
                let isSelected = viewModel.selectedMode == mode
                Button(action: {
                    HapticFeedback.shared.touchSoft()
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.72)) {
                        viewModel.selectedMode = mode
                    }
                }) {
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.85), Color.blue.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(
                                            LinearGradient(
                                                stops: [
                                                    .init(color: .white.opacity(0.65), location: 0.0),
                                                    .init(color: .cyan.opacity(0.4), location: 0.5),
                                                    .init(color: .white.opacity(0.12), location: 1.0)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.0
                                        )
                                        .allowsHitTesting(false)
                                }
                                .shadow(color: Color.purple.opacity(0.4), radius: 8, x: 0, y: 3)
                                .matchedGeometryEffect(id: "CONVERTER_MODE_PILL", in: modeNamespace)
                        } else {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                        .allowsHitTesting(false)
                                }
                        }

                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .scaleEffect(isSelected ? 1.08 : 1.0)
                            Text(mode.rawValue)
                        }
                        .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? .white : .primary)
                        .padding(.vertical, 12)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Source Media Card
    private var sourceMediaCard: some View {
        GlassCard(cornerRadius: 22, borderOpacity: 0.35) {
            VStack(alignment: .leading, spacing: 12) {
                Text("TỆP NGUỒN CẦN XỬ LÝ:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)

                if let selected = viewModel.selectedMediaItem {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 48, height: 48)
                            Image(systemName: selected.mediaType.systemIcon)
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(selected.filename)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(1)
                            HStack(spacing: 6) {
                                Text(selected.formattedFileSize)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(selected.formattedDuration)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button(action: {
                            showFilePickerSheet = true
                        }) {
                            Text("Đổi")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .glassCapsule(borderOpacity: 0.25)
                                .contentShape(Capsule())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else {
                    Button(action: {
                        HapticFeedback.shared.touchLight()
                        loadAvailableVideos()
                        showFilePickerSheet = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.cyan)

                            Text("Chọn video từ thư viện ứng dụng")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Transcoding Progress Card
    private var transcodingProgressCard: some View {
        GlassCard(cornerRadius: 20, borderOpacity: 0.4) {
            VStack(spacing: 12) {
                HStack {
                    Text("Đang xử lý nội bộ...")
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Text(String(format: "%.0f%%", viewModel.conversionProgress * 100))
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.cyan)
                }

                GlassProgressBar(progress: viewModel.conversionProgress)

                HStack {
                    Text("Tận dụng Apple Neural Engine & GPU")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(action: {
                        viewModel.cancelConversion()
                    }) {
                        Text("Hủy")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }

    // MARK: - File Picker Modal
    private var filePickerModal: some View {
        NavigationView {
            ZStack {
                LiquidBackground()

                if availableItems.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "folder")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Chưa có video nào trong thư viện")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("Hãy tải video từ tab Dashboard trước.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .padding()
                } else {
                    List {
                        ForEach(availableItems) { item in
                            Button(action: {
                                HapticFeedback.shared.touchLight()
                                viewModel.selectedMediaItem = item
                                showFilePickerSheet = false
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: item.mediaType.systemIcon)
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.filename)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        Text("\(item.formattedFileSize) • \(item.formattedDuration)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Chọn Tệp Nguồn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { showFilePickerSheet = false }
                }
            }
        }
    }

    // MARK: - Success Modal
    private var successModal: some View {
        ZStack {
            LiquidBackground()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .padding(.top, 30)

                Text("Chuyển Đổi Thành Công!")
                    .font(.system(size: 22, weight: .bold))

                Text("Tệp mới đã được lưu an toàn vào thư mục Converted trong Files app.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                if let url = viewModel.convertedOutputURL {
                    Text(url.lastPathComponent)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()

                GlassButton("Xong", icon: "checkmark", style: .vibrantGradient) {
                    viewModel.showSuccessSheet = false
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
    }

    private func loadAvailableVideos() {
        Task {
            let items = await StorageManager.shared.scanAllMediaItems()
            await MainActor.run {
                self.availableItems = items.filter { $0.mediaType == .video }
                if viewModel.selectedMediaItem == nil && !availableItems.isEmpty {
                    viewModel.selectedMediaItem = availableItems.first
                }
            }
        }
    }
}
