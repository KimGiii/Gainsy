import SwiftUI

// MARK: - ViewModel (inline)

@MainActor
final class DietLogDetailViewModel: ObservableObject {
    @Published var detail: DietLogDetailResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load(id: Int, apiClient: APIClient) async {
        isLoading = true
        defer { isLoading = false }
        do {
            detail = try await apiClient.request(.getDietLog(id: id))
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "상세 정보를 불러오지 못했습니다."
        }
    }
}

// MARK: - DietLogDetailView

struct DietLogDetailView: View {
    let logId: Int
    let mealType: MealType
    let logDate: String

    @EnvironmentObject private var container: AppContainer
    @StateObject private var viewModel = DietLogDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingSources = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPage.ignoresSafeArea()
            if viewModel.isLoading {
                VStack { Spacer(); ProgressView(); Spacer() }
            } else if let detail = viewModel.detail {
                ScrollView {
                    VStack(spacing: 0) {
                        DietDetailHeader(detail: detail)
                        VStack(spacing: 16) {
                            nutritionCard(detail: detail)
                            entriesSection(detail: detail)
                            if let notes = detail.notes, !notes.isEmpty {
                                notesCard(notes: notes)
                            }
                        }
                        .padding(.horizontal, Spacing.lg) // design-lint:ignore — micro/hero spacing
                        .padding(.top, Spacing.xl) // design-lint:ignore — micro/hero spacing
                        .padding(.bottom, Spacing.xxl) // design-lint:ignore — micro/hero spacing
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .topLeading) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.cta)
                    .foregroundColor(.white)
                    .padding(Spacing.md) // design-lint:ignore — micro/hero spacing
                    .background(Color.black.opacity(0.25))
                    .clipShape(Circle())
            }
            .padding(.leading, Spacing.lg) // design-lint:ignore — micro/hero spacing
            .padding(.top, 56) // design-lint:ignore — micro/hero spacing
        }
        .overlay(alignment: .topTrailing) {
            if viewModel.detail != nil {
                Button {
                    showingEdit = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.cta)
                        .foregroundColor(.white)
                        .padding(Spacing.md) // design-lint:ignore — micro/hero spacing
                        .background(Color.black.opacity(0.25))
                        .clipShape(Circle())
                }
                .padding(.trailing, Spacing.lg) // design-lint:ignore — micro/hero spacing
                .padding(.top, 56) // design-lint:ignore — micro/hero spacing
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let detail = viewModel.detail {
                AddDietLogView(editing: detail) {
                    showingEdit = false
                    Task { await viewModel.load(id: logId, apiClient: container.apiClient) }
                }
                .environmentObject(container)
            }
        }
        .task { await viewModel.load(id: logId, apiClient: container.apiClient) }
        .sheet(isPresented: $showingSources) { MedicalSourcesView() }
    }

    private func nutritionCard(detail: DietLogDetailResponse) -> some View {
        VStack(spacing: 14) {
            HStack {
                Text("영양 정보")
                    .font(.subheadline.bold())
                    .foregroundColor(Color.brandAccent)
                Spacer()
                Button {
                    showingSources = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                }
                .accessibilityLabel("영양 정보 출처 보기")
            }
            HStack(spacing: 0) {
                NutritionStatCell(
                    label: "칼로리",
                    value: String(format: "%.0f", detail.totalCalories ?? 0),
                    unit: "kcal",
                    color: .brandAccent
                )
                Divider().frame(height: 40)
                NutritionStatCell(
                    label: "단백질",
                    value: String(format: "%.1f", detail.totalProteinG ?? 0),
                    unit: "g",
                    color: .blue
                )
                Divider().frame(height: 40)
                NutritionStatCell(
                    label: "탄수화물",
                    value: String(format: "%.1f", detail.totalCarbsG ?? 0),
                    unit: "g",
                    color: .orange
                )
                Divider().frame(height: 40)
                NutritionStatCell(
                    label: "지방",
                    value: String(format: "%.1f", detail.totalFatG ?? 0),
                    unit: "g",
                    color: .pink
                )
            }
        }
        .padding(Spacing.lg) // design-lint:ignore — micro/hero spacing
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func entriesSection(detail: DietLogDetailResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("식품 목록")
                .font(.subheadline.bold())
                .foregroundColor(Color.textSecondary)
            VStack(spacing: 1) {
                ForEach(Array(detail.entries.enumerated()), id: \.element.id) { idx, entry in
                    FoodEntryRow(entry: entry)
                    if idx < detail.entries.count - 1 {
                        Divider().padding(.leading, 56) // design-lint:ignore — micro/hero spacing
                    }
                }
            }
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }

    private func notesCard(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("메모", systemImage: "note.text")
                .font(.subheadline.bold())
                .foregroundColor(Color.textSecondary)
            Text(notes)
                .font(.body)
                .foregroundColor(Color.textHeadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.lg) // design-lint:ignore — micro/hero spacing
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - DietDetailHeader (Wave 헤더)

private struct DietDetailHeader: View {
    let detail: DietLogDetailResponse

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.brandPrimary
            DietDetailWaveCurve()
                .fill(Color.backgroundPage)
                .frame(height: 40)
                .offset(y: 1)

            VStack(spacing: 6) {
                Image(systemName: detail.mealType.sfSymbol)
                    .font(.system(size: 40))
                Text(detail.mealType.displayName)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text(formattedDate(detail.logDate))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.top, 80) // design-lint:ignore — micro/hero spacing
            .padding(.bottom, 48) // design-lint:ignore — micro/hero spacing
        }
        .frame(maxWidth: .infinity)
    }

    private func formattedDate(_ s: String) -> String {
        let parts = s.split(separator: "-")
        guard parts.count == 3 else { return s }
        return "\(parts[0])년 \(parts[1])월 \(parts[2])일"
    }
}

private struct DietDetailWaveCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control1: CGPoint(x: rect.width * 0.3, y: rect.minY),
            control2: CGPoint(x: rect.width * 0.7, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - NutritionStatCell

private struct NutritionStatCell: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(color)
            Text(unit)
                .font(.caption2)
                .foregroundColor(Color.textSecondary)
            Text(label)
                .font(.caption2)
                .foregroundColor(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - FoodEntryRow

private struct FoodEntryRow: View {
    let entry: FoodEntryResponse

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.category?.sfSymbol ?? "fork.knife")
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(Color.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.displayName)
                    .font(.subheadline.bold())
                Text(String(format: "%.0fg", entry.servingG))
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
            Spacer()
            Text(entry.calories.map { String(format: "%.0f kcal", $0) } ?? "-")
                .font(.subheadline.bold())
                .foregroundColor(.brandAccent)
        }
        .padding(.horizontal, Spacing.lg) // design-lint:ignore — micro/hero spacing
        .padding(.vertical, Spacing.md) // design-lint:ignore — micro/hero spacing
    }
}

private extension Optional where Wrapped == Double {
    func map(_ transform: (Double) -> String) -> String? {
        guard let self = self else { return nil }
        return transform(self)
    }
}
