import SwiftUI

struct MyPageView: View {
    @StateObject private var viewModel = MyPageViewModel()
    @EnvironmentObject private var authState: AuthState
    @EnvironmentObject private var container: AppContainer

    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @State private var showMedicalSources = false
    @AppStorage("appTheme") private var appThemeRawValue = AppTheme.system.rawValue

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appThemeRawValue) ?? .system
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    profileCard
                    menuSections
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color.backgroundPage)
            .navigationTitle("마이페이지")
            .navigationBarTitleDisplayMode(.large)
            .alert("오류", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .confirmationDialog("계정을 삭제하면 모든 데이터가 영구 삭제됩니다.", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("계정 삭제", role: .destructive) {
                    Task { await viewModel.deleteAccount(apiClient: container.apiClient, authState: authState) }
                }
                Button("취소", role: .cancel) {}
            }
            .sheet(isPresented: $showEditSheet) {
                EditProfileSheet(viewModel: viewModel, isPresented: $showEditSheet)
                    .environmentObject(container)
            }
            .sheet(isPresented: $showMedicalSources) {
                MedicalSourcesView()
            }
        }
        .refreshable {
            await viewModel.load(apiClient: container.apiClient, authState: authState)
            // pull-to-refresh로 인한 실패는 alert으로 알리지 않음(기존 화면 데이터 유지).
            viewModel.errorMessage = nil
        }
        .task { await viewModel.load(apiClient: container.apiClient, authState: authState) }
        // 신체 측정 기록이 추가/수정/삭제되면 백엔드가 User.weightKg를 동기화하므로
        // 마이페이지도 즉시 다시 가져와 최신 체중을 표시.
        .onReceive(NotificationCenter.default.publisher(for: .bodyMeasurementDidChange)) { _ in
            Task { await viewModel.load(apiClient: container.apiClient, authState: authState) }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 20) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.forestHero)
                        .frame(width: 84, height: 84)
                        .overlay(
                            Circle().stroke(Color.brandAccent.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: Color.brandAccent.opacity(0.25), radius: 12, x: 0, y: 4)
                    Text(viewModel.profile?.displayName.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 6) {
                    Text(viewModel.profile?.displayName ?? "불러오는 중...")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.textHeadline)
                    Text(viewModel.profile?.email ?? "")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.brandAccent)
                }
            }
            .padding(.top, 24)

            statsRow
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.hairline, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(
                label: "키",
                value: viewModel.profile?.heightCm.map { "\(Int($0))cm" } ?? "-"
            )
            statDivider
            statCell(
                label: "체중",
                value: viewModel.profile?.weightKg.map { String(format: "%.1fkg", $0) } ?? "-"
            )
            statDivider
            statCell(
                label: "활동량",
                value: viewModel.activityLevelLabel
            )
            statDivider
            statCell(
                label: "성별",
                value: viewModel.sexLabel
            )
        }
        .padding(.vertical, 14)
        .background(Color.backgroundPage)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.hairline)
            .frame(width: 1, height: 32)
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textHeadline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Menu Sections

    private var menuSections: some View {
        VStack(spacing: 20) {
            MenuSection(title: "계정 관리") {
                MenuRow(icon: "person.crop.circle", iconColor: Color.brandSecondary, label: "프로필 수정") {
                    viewModel.populateEditFields()
                    showEditSheet = true
                }
            }

            MenuSection(title: "앱 설정") {
                ThemeMenuRow(selectedTheme: selectedTheme) { theme in
                    appThemeRawValue = theme.rawValue
                }
            }

            MenuSection(title: "앱 정보") {
                MenuRow(
                    icon: "info.circle",
                    iconColor: Color.brandMoss,
                    label: "버전",
                    trailingText: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
                    action: {}
                )
                Divider().padding(.leading, 60)
                MenuRow(
                    icon: "book.closed",
                    iconColor: Color.brandMoss,
                    label: "의학 정보 출처"
                ) {
                    showMedicalSources = true
                }
                Divider().padding(.leading, 60)
                MenuLinkRow(
                    icon: "doc.text",
                    iconColor: Color.brandSecondary,
                    label: "이용약관",
                    url: URL(string: "https://kimgiii.github.io/Gainsy/docs/legal/terms.html")!
                )
                Divider().padding(.leading, 60)
                MenuLinkRow(
                    icon: "hand.raised",
                    iconColor: Color.brandSecondary,
                    label: "개인정보처리방침",
                    url: URL(string: "https://kimgiii.github.io/Gainsy/docs/legal/privacy.html")!
                )
            }

            MenuSection(title: "") {
                MenuRow(icon: "rectangle.portrait.and.arrow.right", iconColor: Color.brandWarning, label: "로그아웃") {
                    viewModel.logout(authState: authState)
                }
                MenuRow(icon: "trash", iconColor: Color.brandDanger, label: "계정 삭제") {
                    showDeleteConfirm = true
                }
            }
        }
    }
}

// MARK: - Edit Profile Sheet

private struct EditProfileSheet: View {
    @ObservedObject var viewModel: MyPageViewModel
    @Binding var isPresented: Bool
    @EnvironmentObject private var container: AppContainer
    @Environment(\.dismiss) private var dismiss

    let sexOptions = [("남성", "MALE"), ("여성", "FEMALE")]
    let activityOptions: [ActivityOptionRow] = ActivityLevelOption.all.map {
        ActivityOptionRow(label: $0.label, value: $0.value)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    EditCard(title: "기본 정보") {
                        EditField(label: "닉네임", placeholder: "닉네임을 입력하세요", text: $viewModel.editDisplayName)
                        Divider().padding(.leading, 16)
                        EditPickerField(label: "성별", value: viewModel.editSex, options: sexOptions) { v in
                            viewModel.editSex = v
                        }
                    }

                    EditCard(title: "신체 정보") {
                        EditNumericField(label: "키", unit: "cm", text: $viewModel.editHeightCm)
                        Divider().padding(.leading, 16)
                        EditNumericField(label: "체중", unit: "kg", text: $viewModel.editWeightKg)
                    }

                    EditCard(title: "활동량") {
                        VStack(spacing: 0) {
                            ForEach(activityOptions) { option in
                                Button {
                                    viewModel.editActivityLevel = option.value
                                } label: {
                                    HStack {
                                        Text(option.label)
                                            .font(.bodyMedium)
                                            .foregroundStyle(Color.textPrimary)
                                        Spacer()
                                        if viewModel.editActivityLevel == option.value {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(Color.brandAccent)
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                }
                                if option.value != activityOptions.last?.value {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                    }

                    Button {
                        Task {
                            await viewModel.saveProfile(apiClient: container.apiClient)
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("저장하기")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.brandPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(20)
                .padding(.bottom, 20)
            }
            .background(Color.backgroundPage)
            .navigationTitle("프로필 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
}

private struct ActivityOptionRow: Identifiable {
    let label: String
    let value: String

    var id: String { value }
}

// MARK: - Reusable Components

private struct MenuSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.eyebrow)
                    .tracking(1.5)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, 4)
            }
            VStack(spacing: 0) {
                content()
            }
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }
}

private struct MenuRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let trailingText: String?
    let action: () -> Void

    init(icon: String, iconColor: Color, label: String, trailingText: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.iconColor = iconColor
        self.label = label
        self.trailingText = trailingText
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)
                    .frame(width: 30, height: 30)
                    .background(iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(label)
                    .font(.bodyMedium)
                    .foregroundStyle(
                        label == "계정 삭제" ? Color.brandDanger : Color.textPrimary
                    )

                Spacer()

                if let t = trailingText {
                    Text(t)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.textSecondary.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

private struct MenuLinkRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)
                    .frame(width: 30, height: 30)
                    .background(iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(label)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

private struct ThemeMenuRow: View {
    let selectedTheme: AppTheme
    let onSelect: (AppTheme) -> Void

    var body: some View {
        Menu {
            ForEach(AppTheme.allCases) { theme in
                Button {
                    onSelect(theme)
                } label: {
                    Label(theme.title, systemImage: theme == selectedTheme ? "checkmark" : theme.iconName)
                }
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: selectedTheme.iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.brandAccent)
                    .frame(width: 30, height: 30)
                    .background(Color.brandAccent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("화면 모드")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Text(selectedTheme.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.brandAccent)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

private struct EditCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.eyebrow)
                .tracking(1.5)
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                content()
            }
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }
}

private struct EditField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 64, alignment: .leading)
            TextField(placeholder, text: $text)
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

private struct EditNumericField: View {
    let label: String
    let unit: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 64, alignment: .leading)
            Spacer()
            HStack(spacing: 4) {
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 72)
                Text(unit)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

private struct EditPickerField: View {
    let label: String
    let value: String
    let options: [(String, String)]
    let onSelect: (String) -> Void

    private var displayLabel: String {
        options.first(where: { $0.1 == value })?.0 ?? "선택"
    }

    var body: some View {
        Menu {
            ForEach(options, id: \.1) { name, key in
                Button(name) { onSelect(key) }
            }
        } label: {
            HStack {
                Text(label)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 64, alignment: .leading)
                Spacer()
                Text(displayLabel)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
    }
}
