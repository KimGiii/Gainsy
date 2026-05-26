import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var authState: AuthState
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        ZStack {
            Color.backgroundPage.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    BrandLogoView(size: 72, color: Color.brandPrimary)
                        .padding(.bottom, 4)

                    Text("다시 만나서 반가워요")
                        .font(.headingLarge)
                        .foregroundStyle(Color.brandPrimary)

                    Text("계속하려면 로그인해 주세요")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 36)

                // Form
                VStack(spacing: 14) {
                    StyledTextField(
                        icon:        "envelope",
                        placeholder: "이메일",
                        text:        $viewModel.email
                    )
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                    StyledSecureField(
                        icon:        "lock",
                        placeholder: "비밀번호",
                        text:        $viewModel.password
                    )
                }
                .padding(.horizontal, 28)

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.brandDanger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                        .padding(.top, 8)
                }

                Spacer()

                // CTA
                PrimaryButton(
                    "로그인하기",
                    isEnabled: !viewModel.email.isEmpty && !viewModel.password.isEmpty,
                    isLoading: viewModel.isLoading
                ) {
                    Task { await viewModel.login(apiClient: container.apiClient, authState: authState) }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// StyledTextField/StyledSecureField는 DesignSystem/Components/StyledTextField.swift로 승격됨.
