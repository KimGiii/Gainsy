import SwiftUI

// MARK: - Add Session View

struct AddExerciseSessionView: View {
    @StateObject private var viewModel: AddExerciseSessionViewModel
    @EnvironmentObject private var container: AppContainer
    @Environment(\.dismiss) private var dismiss

    let onSaved: (CreateSessionResponse) -> Void

    init(initialDate: Date = Date(), onSaved: @escaping (CreateSessionResponse) -> Void) {
        _viewModel = StateObject(
            wrappedValue: AddExerciseSessionViewModel(initialDate: initialDate)
        )
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 날짜 선택
                    dateSection

                    // 운동 시간
                    durationSection

                    // 세트 목록
                    setsSection

                    // 메모
                    notesSection

                    // 저장 버튼
                    saveButton

                    Color.clear.frame(height: 20)
                }
                .padding(.top, 8)
            }
            .background(Color.backgroundPage)
            .navigationTitle("운동 기록 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .alert("오류", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $viewModel.showCatalogPicker) {
                ExerciseCatalogPickerView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("날짜")

            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.brandAccent)
                DatePicker("", selection: $viewModel.sessionDate, displayedComponents: .date)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ko_KR"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 16)
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("운동 시간")

            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: $viewModel.includeSessionTime) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("칼로리 계산에 운동 시간 반영")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        Text("웨이트와 맨몸 운동은 시간을 입력해야 칼로리 추정이 더 정확해집니다")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .tint(Color.brandPrimary)

                if viewModel.includeSessionTime {
                    HStack(spacing: 10) {
                        timePickerCard(title: "시작", selection: $viewModel.sessionStartTime)
                        timePickerCard(title: "종료", selection: $viewModel.sessionEndTime)
                    }

                    HStack {
                        Label {
                            Text(viewModel.sessionDurationMinutes.map { "총 \($0)분" } ?? "시간을 확인해주세요")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(viewModel.hasValidSessionTime ? Color.brandAccent : Color.brandDanger)
                        } icon: {
                            Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                                .foregroundStyle(viewModel.hasValidSessionTime ? Color.brandAccent : Color.brandDanger)
                        }
                        Spacer()
                    }

                    if !viewModel.hasValidSessionTime {
                        Text("종료 시간은 시작 시간보다 늦어야 합니다.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.brandDanger)
                    }
                } else {
                    Text("시간을 입력하지 않으면 서버가 세트 수 기준의 대략적인 값으로 칼로리를 추정합니다.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(16)
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Sets Section

    private var setsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("세트 구성")
                    .padding(.horizontal, 0)
                Spacer()
                if !viewModel.exerciseGroups.isEmpty {
                    let totalSets = viewModel.exerciseGroups.map(\.sets.count).reduce(0, +)
                    Text("\(totalSets)세트")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.horizontal, 16)

            if viewModel.exerciseGroups.isEmpty {
                // 빈 상태 — 운동 추가 유도
                Button {
                    viewModel.showCatalogPicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.brandAccent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("운동 추가하기")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.brandAccent)
                            Text("카탈로그에서 운동을 검색해 세트를 구성하세요")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.brandAccent.opacity(0.4), lineWidth: 1.5)
                    )
                }
                .padding(.horizontal, 16)
            } else {
                // 운동 그룹 카드들
                VStack(spacing: 12) {
                    ForEach(viewModel.exerciseGroups.indices, id: \.self) { groupIdx in
                        ExerciseGroupCard(
                            groupIndex: groupIdx,
                            group: $viewModel.exerciseGroups[groupIdx],
                            onAddSet: { viewModel.addSetToGroup(at: groupIdx) },
                            onDeleteGroup: { viewModel.removeExerciseGroup(at: groupIdx) },
                            onDeleteSet: { setIdx in viewModel.removeSet(groupIndex: groupIdx, setIndex: setIdx) }
                        )
                    }
                }
                .padding(.horizontal, 16)

                // 운동 추가 버튼
                Button {
                    viewModel.showCatalogPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("운동 추가")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Color.brandAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("메모 (선택)")

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "note.text")
                    .foregroundStyle(Color.textSecondary)
                    .padding(.top, 2)
                TextField("오늘 운동 느낌이나 컨디션 메모...", text: $viewModel.sessionNotes, axis: .vertical)
                    .font(.system(size: 15))
                    .lineLimit(2...4)
            }
            .padding(14)
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task {
                await viewModel.save(apiClient: container.apiClient) { response in
                    onSaved(response)
                    dismiss()
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.4))
                        AdsManager.shared.showInterstitialIfReady()
                    }
                }
            }
        } label: {
            Group {
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("기록 저장")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                viewModel.canSave
                    ? Color.brandPrimary
                    : Color.brandPrimary.opacity(0.35)
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(
                color: viewModel.canSave ? Color.brandPrimary.opacity(0.35) : .clear,
                radius: 10, x: 0, y: 4
            )
        }
        .disabled(!viewModel.canSave || viewModel.isSaving)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.textSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
    }

    private func timePickerCard(title: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)

            DatePicker(
                "",
                selection: selection,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .environment(\.locale, Locale(identifier: "ko_KR"))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundPage)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Exercise Group Card (운동 1개 + 세트 목록)

private struct ExerciseGroupCard: View {
    let groupIndex: Int
    @Binding var group: AddExerciseSessionViewModel.ExerciseGroup
    let onAddSet: () -> Void
    let onDeleteGroup: () -> Void
    let onDeleteSet: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 운동 헤더
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.exercise.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(group.exercise.muscleGroupLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Button(action: onAddSet) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 15))
                        Text("세트 추가").font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color.brandAccent)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.surfaceCard).clipShape(Capsule())
                }
                Button(action: onDeleteGroup) {
                    Image(systemName: "trash").font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary.opacity(0.5))
                }
            }
            .padding(14)
            .background(Color.surfaceCard)

            Divider()

            // 세트 행들
            VStack(spacing: 0) {
                ForEach(group.sets.indices, id: \.self) { setIdx in
                    DraftSetRow(
                        setNumber: group.sets[setIdx].setNumber,
                        draft: $group.sets[setIdx],
                        onDelete: { onDeleteSet(setIdx) }
                    )
                    if setIdx < group.sets.count - 1 { Divider().padding(.leading, 14) }
                }
            }
            .background(Color.surfaceCard)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Draft Set Row (세트 1행)

private struct DraftSetRow: View {
    let setNumber: Int
    @Binding var draft: AddExerciseSessionViewModel.DraftSet
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("세트 \(setNumber)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.brandAccent)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.surfaceCard).clipShape(Capsule())

                // 세트 타입 피커
                HStack(spacing: 4) {
                    ForEach(AddExerciseSessionViewModel.DraftSet.SetTypeOption.allCases, id: \.self) { opt in
                        Button { draft.setType = opt } label: {
                            Text(opt.label)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(draft.setType == opt ? .white : Color.brandAccent)
                                .padding(.horizontal, 9).padding(.vertical, 4)
                                .background(draft.setType == opt ? Color.brandAccent : Color.brandAccent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.brandDanger.opacity(0.7))
                }
            }

            // 입력 필드
            switch draft.setType {
            case .weighted:
                HStack(spacing: 10) {
                    inputField("무게", unit: "kg", text: $draft.weightKgText, keyboard: .decimalPad)
                    inputField("횟수", unit: "회", text: $draft.repsText, keyboard: .numberPad)
                }
            case .bodyweight:
                inputField("횟수", unit: "회", text: $draft.repsText, keyboard: .numberPad)
            case .cardio:
                HStack(spacing: 10) {
                    inputField("시간", unit: "분", text: $draft.durationMinutesText, keyboard: .decimalPad)
                    inputField("거리", unit: "m", text: $draft.distanceMText, keyboard: .decimalPad)
                }
            }
        }
        .padding(14)
    }

    private func inputField(_ placeholder: String, unit: String,
                            text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        HStack(spacing: 4) {
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.trailing)
            Text(unit).font(.system(size: 12)).foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Color.backgroundPage)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Catalog Picker Sheet

struct ExerciseCatalogPickerView: View {
    @ObservedObject var viewModel: AddExerciseSessionViewModel
    @EnvironmentObject private var container: AppContainer
    @Environment(\.dismiss) private var dismiss
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 검색 바
                searchBar
                    .padding(16)
                    .background(Color.surfaceCard)

                Divider()

                // 결과
                Group {
                    if viewModel.isSearchingCatalog {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.catalogResults.isEmpty && !viewModel.catalogQuery.isEmpty && viewModel.selectedMuscleGroup == nil {
                        emptySearchResult
                    } else if viewModel.catalogResults.isEmpty && viewModel.selectedMuscleGroup == nil && viewModel.catalogQuery.isEmpty {
                        muscleGroupGrid
                    } else if viewModel.catalogResults.isEmpty {
                        emptySearchResult
                    } else {
                        catalogList
                    }
                }
            }
            .background(Color.backgroundPage)
            .navigationTitle("운동 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("검색") {
                        Task { await viewModel.searchCatalog(apiClient: container.apiClient) }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandAccent)
                }
            }
            .onAppear { searchFocused = true }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textSecondary)

            TextField("운동 검색 (예: 벤치프레스, 스쿼트)", text: $viewModel.catalogQuery)
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit {
                    Task { await viewModel.searchCatalog(apiClient: container.apiClient) }
                }

            if !viewModel.catalogQuery.isEmpty {
                Button {
                    viewModel.clearCatalogSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.textSecondary.opacity(0.6))
                }
            }
        }
        .padding(12)
        .background(Color.backgroundPage)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var catalogList: some View {
        VStack(spacing: 0) {
            if let selected = viewModel.selectedMuscleGroup {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .foregroundStyle(Color.brandAccent)
                        .font(.system(size: 14))
                    Text(MuscleGroupMeta.label(for: selected))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.brandAccent)
                    Text("·")
                        .foregroundStyle(Color.textSecondary.opacity(0.5))
                    Text("\(viewModel.catalogResults.count)개")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                    Button {
                        viewModel.clearCatalogSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.textSecondary.opacity(0.5))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.surfaceCard)
                Divider()
            }
            List(viewModel.catalogResults) { item in
                Button {
                    viewModel.addExercise(item)
                    dismiss()
                } label: {
                    CatalogRow(item: item)
                }
                .listRowBackground(Color.surfaceCard)
                .listRowSeparatorTint(Color(uiColor: .separator).opacity(0.5))
            }
            .listStyle(.plain)
        }
    }

    private var muscleGroupGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("부위별 운동")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Text("운동할 부위를 선택하면 해당 운동 목록을 볼 수 있어요")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.horizontal, 4)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(MuscleGroupMeta.all, id: \.key) { meta in
                        Button {
                            Task {
                                await viewModel.selectMuscleGroup(meta.key, apiClient: container.apiClient)
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Text(meta.emoji)
                                    .font(.system(size: 28))
                                Text(meta.label)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.surfaceCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
    }

    private var emptySearchResult: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(Color.textSecondary.opacity(0.6))
            Text("'\(viewModel.catalogQuery)'에 대한 결과 없음")
                .font(.system(size: 15))
                .foregroundStyle(Color.textSecondary)

            // Codex 작업: 검색 결과가 없을 때 AI 운동 추정 플로우를 화면에 연결합니다.
            if let estimate = viewModel.aiEstimateResult {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("AI 운동 추정", systemImage: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.brandAccent)
                        Spacer()
                        Text("신뢰도 \(Int(estimate.confidence * 100))%")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Text(estimate.exerciseName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)

                    HStack(spacing: 8) {
                        aiExerciseTag(estimate.muscleGroup)
                        aiExerciseTag(estimate.exerciseType)
                        aiExerciseTag(String(format: "MET %.1f", estimate.metValue))
                    }

                    Text(estimate.disclaimer)
                        .font(.caption)
                        .foregroundStyle(Color.brandWarning)

                    Button {
                        Task {
                            await viewModel.addAiEstimatedExercise(apiClient: container.apiClient)
                            dismiss()
                        }
                    } label: {
                        Label("추정값으로 추가", systemImage: "plus.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.brandPrimary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
            } else {
                Button {
                    Task {
                        await viewModel.estimateWithAI(apiClient: container.apiClient)
                    }
                } label: {
                    if viewModel.isAiEstimating {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("AI로 운동 추정", systemImage: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandPrimary)
                .disabled(viewModel.isAiEstimating)
                .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func aiExerciseTag(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(Color.brandAccent)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.surfaceCard)
            .clipShape(Capsule())
    }
}

// MARK: - Muscle Group Meta

private struct MuscleGroupMeta {
    let key: String
    let label: String
    let emoji: String

    static let all: [MuscleGroupMeta] = [
        .init(key: "CHEST",      label: "가슴",    emoji: "💪"),
        .init(key: "BACK",       label: "등",      emoji: "🔙"),
        .init(key: "SHOULDERS",  label: "어깨",    emoji: "🏋️"),
        .init(key: "BICEPS",     label: "이두",    emoji: "💪"),
        .init(key: "TRICEPS",    label: "삼두",    emoji: "🦾"),
        .init(key: "CORE",       label: "코어",    emoji: "🔥"),
        .init(key: "QUADRICEPS", label: "대퇴사두", emoji: "🦵"),
        .init(key: "HAMSTRINGS", label: "햄스트링", emoji: "🦿"),
        .init(key: "GLUTES",     label: "둔근",    emoji: "🍑"),
        .init(key: "CALVES",     label: "종아리",  emoji: "🦶"),
        .init(key: "FULL_BODY",  label: "전신",    emoji: "🤸"),
        .init(key: "CARDIO",     label: "유산소",  emoji: "🏃"),
    ]

    static func label(for key: String) -> String {
        all.first { $0.key == key }?.label ?? key
    }
}

// MARK: - Catalog Row

private struct CatalogRow: View {
    let item: ExerciseCatalogItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: exerciseIcon(for: item.exerciseType))
                .font(.system(size: 18))
                .foregroundStyle(Color.brandAccent)
                .frame(width: 40, height: 40)
                .background(Color.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                HStack(spacing: 5) {
                    Text(item.muscleGroupLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                    Text("·")
                        .foregroundStyle(Color.textSecondary.opacity(0.5))
                    Text(item.exerciseTypeLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.brandAccent)
                }
            }

            Spacer()

            if item.custom {
                Text("커스텀")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.brandWarning)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.brandWarning.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 6)
    }

    private func exerciseIcon(for type: String) -> String {
        switch type {
        case "CARDIO":      return "figure.run"
        case "BODYWEIGHT":  return "figure.gymnastics"
        case "FLEXIBILITY": return "figure.flexibility"
        default:            return "dumbbell.fill"
        }
    }
}
