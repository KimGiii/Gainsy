# 식품 카탈로그 기술 가이드

**작성일**: 2026-05-04  
**상태**: MVP 구현 완료

## 개요

HealthCare 앱의 식품 카탈로그는 공공 데이터(식품디비) + 사용자 커스텀 식품의 조합으로 운영됩니다. 이 문서는 2026-05-04에 구현된 **사용 횟수 추적** 및 **사용자 직접 등록** 기능을 설명합니다.

## 주요 기능

### 1. 식품 사용 횟수 추적 (usage_count)

#### 데이터베이스 변경 (V13 마이그레이션)

```sql
ALTER TABLE food_catalog ADD COLUMN usage_count BIGINT NOT NULL DEFAULT 0;
```

#### 카운팅 규칙

1. **식단 기록 추가 시**
   - 기록에 포함된 모든 식품의 distinct 셋에 대해 `usage_count` +1
   - 같은 식품이 여러 번 추가되어도 1회만 카운팅

2. **식단 기록 삭제 시**
   - 기록에 포함된 모든 식품의 distinct 셋에 대해 `usage_count` -1
   - `usage_count`는 0 미만으로 떨어지지 않음 (max(0, current-1))

#### 구현 위치

```
backend/src/main/java/com/healthcare/domain/diet/
├── service/DietLogService.java          # increment/decrement 로직
├── repository/FoodCatalogRepository.java # incrementUsageCount(), decrementUsageCount()
└── entity/FoodCatalog.java              # usageCount 필드
```

### 2. 검색 결과 정렬

`GET /api/v1/diet/catalog?searchTerm=<term>` 응답 정렬 순서:

1. **이름 접두사 매칭** (가장 높은 우선순위)
   - 정확한 prefix 매칭인 항목 먼저
   
2. **사용 횟수 내림차순** (usage_count DESC)
   - 사용자가 자주 기록한 식품 우선
   
3. **이름 가나다순** (name ASC)
   - 같은 사용 횟수면 이름 순서

#### 쿼리 예시

```java
// FoodCatalogRepository.searchAll()
SELECT f FROM FoodCatalog f
WHERE LOWER(f.name) LIKE :searchLower
ORDER BY 
  CASE WHEN LOWER(f.name) LIKE :prefixLower THEN 0 ELSE 1 END,
  f.usageCount DESC,
  f.name ASC
```

### 3. 사용자 직접 식품 등록 (Custom Food)

#### API 엔드포인트

```
POST /api/v1/diet/catalog
Content-Type: application/json
Authorization: Bearer {token} (선택 사항, 최초 사용자 구분용)

Request body:
{
  "name": "된장찌개",
  "category": "SOUP",
  "calories": 150,
  "protein": 8.0,
  "carbs": 20.0,
  "fat": 5.0
}

Response (201 Created):
{
  "id": 12345,
  "name": "된장찌개",
  "category": "SOUP",
  "calories": 150,
  "protein": 8.0,
  "carbs": 20.0,
  "fat": 5.0,
  "usageCount": 0,
  "createdByUserId": "user-uuid",
  "source": "CUSTOM"
}
```

#### 검색 API 공개화

```
GET /api/v1/diet/catalog?searchTerm=<term>
Authorization: (선택 사항)
```

- **이전 동작**: 로그인한 사용자의 커스텀 식품만 반환
- **현재 동작**: 모든 커스텀 식품 반환 (미인증 사용자도 검색 가능)

#### 입력 검증 및 정규화

##### Bean Validation (`CreateCustomFoodRequest`)

```java
@NotBlank
@Length(max = 100)
private String name;  // 공백, 100자 이내

@NotNull
@Min(0) @Max(9999)
private Integer calories;  // 0~9999

@Min(0) @Max(100)
private Double protein;  // 단백질 (선택 사항, 0~100)

@Min(0) @Max(100)
private Double carbs;    // 탄수화물 (선택 사항, 0~100)

@Min(0) @Max(100)
private Double fat;      // 지방 (선택 사항, 0~100)
```

##### 입력 정규화 (`FoodCatalogService.createCustomFood()`)

1. **NFC Unicode 정규화**
   - 한글 자모 조합 통일 (예: 된↓장 → 된장)
   
2. **연속 공백 축약**
   - 공백 2개 이상 → 1개로 축약
   - 양 끝 공백 제거 (trim)

3. **중복 검사**
   - 같은 이름+카테고리 조합이 이미 존재하면 409 Conflict
   - 앱 내에서 자동 응답 처리 (기존 항목 재사용)

#### 구현 위치

```
backend/src/main/java/com/healthcare/domain/diet/
├── controller/FoodCatalogController.java     # POST /api/v1/diet/catalog
├── service/FoodCatalogService.java           # createCustomFood 로직
├── dto/CreateCustomFoodRequest.java          # Bean Validation
├── dto/FoodCatalogResponse.java              # 응답 DTO
└── repository/FoodCatalogRepository.java      # 중복 검사 쿼리
```

## iOS 구현

### 1. 검색 결과 중복 제거

**문제**: 공공 데이터(식품디비) + 커스텀 식품 검색 시 같은 식품명이 중복되어 나타남

**해결책**: `displayName` 기준 `uniqued(by:)` 처리

```swift
// Date+Formatting.swift
extension Array {
  func uniqued(by keyPath: KeyPath<Element, some Hashable>) -> [Element] {
    var seen = Set<AnyHashable>()
    return filter { element in
      let key = AnyHashable(element[keyPath: keyPath])
      guard !seen.contains(key) else { return false }
      seen.insert(key)
      return true
    }
  }
}

// AddDietLogView
let uniqueCatalogResults = catalogResults.uniqued(by: \.displayName)
let uniqueExternalResults = externalResults.uniqued(by: \.displayName)
```

### 2. 직접 등록 화면 (`AddCustomFoodView`)

#### UI 구성

```
┌─────────────────────────────────┐
│ 직접 등록하기                     │
├─────────────────────────────────┤
│ 식품명                           │
│ [된장찌개            ]           │
│                                  │
│ 카테고리                         │
│ [SOUP           ▼]              │
│                                  │
│ 칼로리 (필수)                    │
│ [150            ] kcal          │
│                                  │
│ 단백질                           │
│ [8.0            ] g             │
│                                  │
│ 탄수화물                         │
│ [20.0           ] g             │
│                                  │
│ 지방                             │
│ [5.0            ] g             │
│                                  │
│ [등록]  [취소]                   │
└─────────────────────────────────┘
```

#### 기능

1. **자동 검색어 채움**
   - `.onAppear`에서 부모 ViewModel의 검색어를 name 필드에 복사
   
2. **입력 검증**
   - 식품명: 필수
   - 칼로리: 필수, 0~9999 범위
   - 기타 항목: 선택 사항, 0~100 범위
   
3. **등록 성공 시**
   - 새로운 식품을 검색 결과 맨 위에 prepend
   - 자동 선택 (탭 전환 없이 바로 기록)
   - dismiss

#### 구현 위치

```
ios/HealthCare/Features/Record/Diet/
├── Views/AddDietLogView.swift          # 빈 상태 UI + AddCustomFoodView 호출
├── Views/AddCustomFoodView.swift       # 직접 등록 폼 (신규)
├── ViewModels/AddDietLogViewModel.swift # submitCustomFood(), showCustomFoodForm
└── Models/DietModels.swift             # CreateCustomFoodRequest 모델
```

### 3. 탭 네비게이션 리셋

**문제**: 탭 전환 후 이전 탭으로 돌아오면 이전 화면 상태 유지

**해결책**: 탭 전환 시 NavigationStack을 루트로 리셋

```swift
// MainTabView.swift
@State private var recordTabPath = NavigationPath()
@State private var exploreTabPath = NavigationPath()

NavigationStack(path: $recordTabPath) {
  RecordHubView()
}
.onAppear {
  // 다른 탭에서 돌아올 때 리셋
  if !isRecordTabActive {
    recordTabPath = NavigationPath()
  }
}
```

## 테스트 커버리지

### 백엔드 단위 테스트

```java
// FoodCatalogServiceTest
- createCustomFood_이미_존재하는_이름_카테고리_조합_중복_거절()
- createCustomFood_NFC_정규화()
- createCustomFood_연속_공백_축약()

// DietLogServiceTest
- addDietLog_식품별_usage_count_increment()
- removeDietLog_식품별_usage_count_decrement()
- removeDietLog_usage_count_최소_0_유지()
```

### iOS 단위 테스트

```swift
// AddDietLogViewModelTests
- submitCustomFood_성공()
- submitCustomFood_네트워크_오류()
- catalogResults_uniqued_by_displayName()
```

## 마이그레이션 가이드

### 기존 데이터베이스 업그레이드

1. **V13 마이그레이션 실행**
   ```bash
   # Flyway가 자동으로 실행됨
   docker compose up -d postgres redis
   ```

2. **초기 usage_count 계산 (선택 사항)**
   ```sql
   -- 기존 식단 기록을 기반으로 usage_count 초기화
   -- (현재는 0부터 시작, 향후 히스토리 분석 시 필요)
   ```

## 알려진 제약 사항 및 향후 개선

1. **식품 승인 프로세스 미실장**
   - 사용자 등록 식품이 즉시 공개됨
   - 향후: 관리자 검수 및 거절 기능 추가

2. **AI 추정 결과 표시 미완료**
   - AI로 추정된 영양성분 표시 UI 미구현
   - 향후: "AI 추정값" 배지 + disclaimer 텍스트 추가

3. **외부 API 장애 대응 미완료**
   - 공공 데이터 API 장애 시 fallback 전략 모호
   - 향후: 회귀 테스트 및 graceful degradation 강화

## 성능 고려사항

### 데이터베이스 인덱싱

```sql
-- V13 마이그레이션에 포함
CREATE INDEX idx_food_catalog_name ON food_catalog(name);
CREATE UNIQUE INDEX idx_food_catalog_name_category 
  ON food_catalog(name, category) 
  WHERE source = 'CUSTOM';
```

### 캐싱 전략

- 식품 검색 결과는 캐싱하지 않음 (usage_count가 자주 변경됨)
- Redis 캐시는 일일 매크로 합계 등에만 사용

## 참고 문서

- [DB 스키마](./DB_SCHEMA.md)
- [API 설계](./API_DESIGN.md)
- [CURRENT_STATUS.md](./CURRENT_STATUS.md) — Phase 3 진행률 100%
