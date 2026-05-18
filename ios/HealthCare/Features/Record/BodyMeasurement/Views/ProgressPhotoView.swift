import SwiftUI

struct ProgressPhotoView: View {
    @StateObject private var viewModel = ProgressPhotoViewModel()
    @EnvironmentObject private var container: AppContainer

    @State private var showAddSheet = false
    @State private var selectedPhoto: ProgressPhotoItem?
    @State private var activeErrorAlert: ErrorAlertItem?
    @State private var photoToDelete: ProgressPhotoItem?
    @State private var showCompareSheet = false

    private let columns = [GridItem(.flexible(), spacing: 3), GridItem(.flexible(), spacing: 3)]

    var body: some View {
        VStack(spacing: 0) {
            typeTabBar
            if viewModel.isCompareMode {
                compareBar
            }
            photoGrid
        }
        .background(Color.surfaceGrouped)
        .navigationTitle("진행 사진")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !viewModel.photosForSelectedType.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.toggleCompareMode()
                        }
                    } label: {
                        Text(viewModel.isCompareMode ? "취소" : "비교")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(viewModel.isCompareMode ? Color.textSecondary : Color.brandPrimary)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.isCompareMode {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddProgressPhotoView(viewModel: viewModel)
                .environmentObject(container)
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo, viewModel: viewModel)
        }
        .sheet(isPresented: $showCompareSheet) {
            if viewModel.compareSelection.count == 2 {
                PhotoCompareView(
                    photoA: viewModel.compareSelection[0],
                    photoB: viewModel.compareSelection[1]
                )
            }
        }
        .alert("사진 삭제", isPresented: Binding(
            get: { photoToDelete != nil },
            set: { if !$0 { photoToDelete = nil } }
        )) {
            Button("삭제", role: .destructive) {
                if let photo = photoToDelete {
                    Task { await viewModel.deletePhoto(photoId: photo.photoId, apiClient: container.apiClient) }
                }
                photoToDelete = nil
            }
            Button("취소", role: .cancel) { photoToDelete = nil }
        } message: {
            Text("이 사진을 삭제하시겠습니까? 되돌릴 수 없습니다.")
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.08))
            }
        }
        .alert(item: $activeErrorAlert) { item in
            Alert(
                title: Text("오류"),
                message: Text(item.message),
                dismissButton: .cancel(Text("확인")) {
                    activeErrorAlert = nil
                    viewModel.errorMessage = nil
                }
            )
        }
        .onChange(of: viewModel.errorMessage) { newValue in
            guard let newValue else { return }
            activeErrorAlert = ErrorAlertItem(message: newValue)
        }
        .task { await viewModel.loadAll(apiClient: container.apiClient) }
    }

    // MARK: - Type Tab Bar

    private var typeTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PhotoType.allCases) { type in
                    let count = viewModel.photosByType[type]?.count ?? 0
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedType = type
                            viewModel.compareSelection.removeAll()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(type.label)
                                .font(.system(size: 13, weight: .semibold))
                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(
                                        viewModel.selectedType == type
                                            ? Color.white.opacity(0.25)
                                            : Color.surfaceCard
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedType == type
                                ? Color.brandPrimary
                                : Color.surfacePrimary
                        )
                        .foregroundStyle(
                            viewModel.selectedType == type ? Color.white : Color.textSecondary
                        )
                        .clipShape(Capsule())
                        .shadow(
                            color: viewModel.selectedType == type
                                ? Color.brandPrimary.opacity(0.3)
                                : .black.opacity(0.05),
                            radius: 4, x: 0, y: 2
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(Color.surfacePrimary)
        .overlay(
            Rectangle().fill(Color.hairline).frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - Compare Bar

    private var compareBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.split.2x1")
                .foregroundStyle(Color.brandPrimary)
                .font(.system(size: 15))
            Text(compareBarLabel)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Button {
                showCompareSheet = true
            } label: {
                Text("비교 보기")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(viewModel.compareSelection.count == 2 ? Color.brandPrimary : Color.textTertiary)
                    .clipShape(Capsule())
            }
            .disabled(viewModel.compareSelection.count != 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.surfaceCard)
        .overlay(Rectangle().fill(Color.hairline).frame(height: 0.5), alignment: .bottom)
    }

    private var compareBarLabel: String {
        switch viewModel.compareSelection.count {
        case 0: return "비교할 사진 2장을 선택하세요"
        case 1: return "1장 선택됨 · 1장 더 선택하세요"
        default: return "2장 선택됨"
        }
    }

    // MARK: - Photo Grid

    @ViewBuilder
    private var photoGrid: some View {
        let photos = viewModel.photosForSelectedType

        if photos.isEmpty {
            emptyState
        } else {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 3) {
                    ForEach(photos) { photo in
                        PhotoGridCell(
                            photo: photo,
                            isCompareMode: viewModel.isCompareMode,
                            isSelected: viewModel.isSelectedForCompare(photo)
                        )
                        .onTapGesture {
                            if viewModel.isCompareMode {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    viewModel.toggleCompareSelection(photo)
                                }
                            } else {
                                selectedPhoto = photo
                            }
                        }
                        .contextMenu {
                            if !viewModel.isCompareMode {
                                Button(role: .destructive) {
                                    photoToDelete = photo
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .refreshable { await viewModel.loadAll(apiClient: container.apiClient) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.surfaceCard)
                    .frame(width: 96, height: 96)
                Image(systemName: "camera")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(Color.brandSecondary)
            }
            VStack(spacing: 8) {
                Text("아직 사진이 없어요")
                    .font(.headingMedium)
                    .foregroundStyle(Color.textPrimary)
                Text("+ 버튼으로 \(viewModel.selectedType.label) 사진을 추가하세요")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                showAddSheet = true
            } label: {
                Text("사진 추가")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 13)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ErrorAlertItem: Identifiable, Equatable {
    let id = UUID()
    let message: String
}

// MARK: - Grid Cell

private struct PhotoGridCell: View {
    let photo: ProgressPhotoItem
    let isCompareMode: Bool
    let isSelected: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: photo.thumbnailURL) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .failure:
                        Color.surfaceSecondary
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundStyle(Color.textTertiary)
                            )
                    default:
                        Color.surfaceSecondary
                            .overlay(ProgressView().scaleEffect(0.8))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.width)
                .clipped()

                VStack(alignment: .leading, spacing: 2) {
                    if photo.isBaseline {
                        Text("기준")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(Color.textHeadline)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.brandAccentGlow)
                            .clipShape(Capsule())
                    }
                    Text(photo.displayDate)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                .padding(8)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.45)],
                        startPoint: .top, endPoint: .bottom
                    )
                )

                if isCompareMode {
                    ZStack(alignment: .topTrailing) {
                        Color.black.opacity(isSelected ? 0 : 0.25)
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.brandPrimary : .white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .padding(8)
                    }
                    .frame(width: geo.size.width, height: geo.size.width)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(Rectangle())
        .overlay(
            isSelected
                ? RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.brandPrimary, lineWidth: 3)
                : nil
        )
    }
}

// MARK: - Detail View

private struct PhotoDetailView: View {
    let photo: ProgressPhotoItem
    @ObservedObject var viewModel: ProgressPhotoViewModel
    @EnvironmentObject private var container: AppContainer
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    AsyncImage(url: photo.originalURL ?? photo.thumbnailURL) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFit()
                        default:
                            Color.surfaceSecondary
                                .frame(height: 360)
                                .overlay(ProgressView())
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 20) {
                        infoRow("포즈", photo.photoType.label)
                        infoRow("촬영일", photo.displayDate)
                        if let w = photo.bodyWeightKg {
                            infoRow("체중", String(format: "%.1f kg", w))
                        }
                        if let wc = photo.waistCm {
                            infoRow("허리", String(format: "%.1f cm", wc))
                        }
                        if let n = photo.notes, !n.isEmpty {
                            infoRow("메모", n)
                        }
                        if photo.isBaseline {
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(Color.brandSunrise)
                                Text("기준 사진으로 설정됨")
                                    .font(.bodyMedium)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                    .padding(24)

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("사진 삭제", systemImage: "trash")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.surfaceGrouped)
            .navigationTitle(photo.photoType.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .alert("사진 삭제", isPresented: $showDeleteConfirm) {
                Button("삭제", role: .destructive) {
                    Task {
                        await viewModel.deletePhoto(photoId: photo.photoId, apiClient: container.apiClient)
                        dismiss()
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("이 사진을 삭제하시겠습니까? 되돌릴 수 없습니다.")
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.bodySmall)
                .foregroundStyle(Color.textTertiary)
                .frame(width: 52, alignment: .leading)
            Text(value)
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
    }
}

// MARK: - Compare View

struct PhotoCompareView: View {
    let photoA: ProgressPhotoItem
    let photoB: ProgressPhotoItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let panelWidth = max(0, geo.size.width / 2 - 1)
                HStack(spacing: 2) {
                    comparePanel(photo: photoA, width: panelWidth)
                    comparePanel(photo: photoB, width: panelWidth)
                }
            }
            .background(Color.black)
            .navigationTitle("비교")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func comparePanel(photo: ProgressPhotoItem, width: CGFloat) -> some View {
        VStack(spacing: 0) {
            AsyncImage(url: photo.originalURL ?? photo.thumbnailURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    Color.gray.opacity(0.3)
                        .overlay(ProgressView().tint(.white))
                }
            }
            .frame(width: width)
            .clipped()
            .frame(maxHeight: .infinity)

            VStack(spacing: 4) {
                Text(photo.displayDate)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                if let w = photo.bodyWeightKg {
                    Text(String(format: "%.1f kg", w))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.85))
        }
    }
}
