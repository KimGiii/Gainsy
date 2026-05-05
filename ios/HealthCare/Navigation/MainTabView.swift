import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var homePath    = NavigationPath()
    @State private var diaryPath   = NavigationPath()
    @State private var recordPath  = NavigationPath()
    @State private var explorePath = NavigationPath()
    @State private var myPagePath  = NavigationPath()

    enum Tab: Int, CaseIterable {
        case home, diary, record, explore, myPage

        var title: String {
            switch self {
            case .home:    return "대시보드"
            case .diary:   return "다이어리"
            case .record:  return "기록"
            case .explore: return "탐색"
            case .myPage:  return "프로필"
            }
        }

        var systemImage: String {
            switch self {
            case .home:    return "square.grid.2x2.fill"
            case .diary:   return "calendar"
            case .record:  return "plus.circle.fill"
            case .explore: return "safari"
            case .myPage:  return "person.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $homePath) {
                HomeView()
            }
            .tabItem { Label(Tab.home.title,    systemImage: Tab.home.systemImage) }
            .tag(Tab.home)

            NavigationStack(path: $diaryPath) {
                DiaryView()
            }
            .tabItem { Label(Tab.diary.title,   systemImage: Tab.diary.systemImage) }
            .tag(Tab.diary)

            NavigationStack(path: $recordPath) {
                RecordHubView(showsDismissButton: false)
            }
            .tabItem { Label(Tab.record.title,  systemImage: Tab.record.systemImage) }
            .tag(Tab.record)

            NavigationStack(path: $explorePath) {
                ExploreView()
            }
            .tabItem { Label(Tab.explore.title, systemImage: Tab.explore.systemImage) }
            .tag(Tab.explore)

            NavigationStack(path: $myPagePath) {
                MyPageView()
            }
            .tabItem { Label(Tab.myPage.title,  systemImage: Tab.myPage.systemImage) }
            .tag(Tab.myPage)
        }
        .tint(Color.brandPrimary)
        .onChange(of: selectedTab) { newTab in
            switch newTab {
            case .home:    homePath    = NavigationPath()
            case .diary:   diaryPath   = NavigationPath()
            case .record:  recordPath  = NavigationPath()
            case .explore: explorePath = NavigationPath()
            case .myPage:  myPagePath  = NavigationPath()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .pushNotificationTapped)) { note in
            guard let type = note.userInfo?["type"] as? String else { return }
            handlePushRoute(type: type)
        }
    }

    private func handlePushRoute(type: String) {
        switch type {
        case "WEEKLY_SUMMARY":
            selectedTab = .explore
            explorePath = NavigationPath()
        default:
            break
        }
    }
}
