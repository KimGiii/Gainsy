import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unknown
    case serverError(statusCode: Int, code: String?, message: String?)
    case decodingError(Error)
    case noNetwork
    case tokenExpired
    case unauthorized
    /// 백엔드가 403 + code="PREMIUM_REQUIRED"로 응답한 경우.
    case premiumRequired

    var errorDescription: String? {
        switch self {
        case .invalidURL:                  return "잘못된 URL입니다."
        case .unknown:                     return "알 수 없는 오류가 발생했습니다."
        case .noNetwork:                   return "네트워크 연결을 확인해 주세요."
        case .tokenExpired:                return "세션이 만료되었습니다. 다시 로그인해 주세요."
        case .unauthorized:                return "인증에 실패했습니다."
        case .premiumRequired:             return "프리미엄 구독이 필요한 기능입니다."
        case .decodingError:               return "서버 응답을 처리할 수 없습니다."
        case .serverError(let status, _, let message):
            // 백엔드가 사용자용 한국어 메시지를 내려주면 우선 사용.
            // 그 외엔 상태코드만 노출해 디버깅 단서 제공.
            if let message, !message.isEmpty { return message }
            return "서버 오류가 발생했습니다. (\(status))"
        }
    }
}
