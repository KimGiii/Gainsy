import Foundation

struct ProfileSetupRequest: Encodable {
    let sex: String?
    let dateOfBirth: String?   // yyyy-MM-dd (백엔드 LocalDate)
    let heightCm: Double
    let weightKg: Double
    let activityLevel: String?
    let onboardingCompleted: Bool
}

struct UserProfile: Decodable {
    let id: Int
    let email: String
    let displayName: String
    let sex: String?
    let dateOfBirth: String?   // yyyy-MM-dd
    let heightCm: Double?
    let weightKg: Double?
    let activityLevel: String?
    let onboardingCompleted: Bool
    let isPremium: Bool?  // 백엔드 미응답 시 false 취급

    var premium: Bool { isPremium ?? false }
}
