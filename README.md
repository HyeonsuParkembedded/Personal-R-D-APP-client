# LabPilot — Flutter Client

LabPilot 백엔드와 연동하는 Flutter 클라이언트 앱입니다.
Android 및 Windows 데스크탑을 지원하며, GitHub/GitLab 연동 대시보드를 포함합니다.

---

## 지원 플랫폼

| 플랫폼 | 상태 |
|--------|------|
| Android (Phone/Tablet) | ✅ 지원 |
| Windows Desktop | ✅ 지원 |
| Linux Desktop | ✅ 지원 (보조) |

---

## 기술 스택

| 항목 | 내용 |
|------|------|
| Flutter SDK | 3.41.4 stable 이상 |
| 상태관리 | StatefulWidget (자체 관리) |
| HTTP 클라이언트 | `http` 패키지 |
| 설정 저장 | `shared_preferences` |
| 반응형 레이아웃 | `responsive_layout.dart` (자체 구현) |

---

## 화면 구성

| 화면 | 설명 |
|------|------|
| `ProjectListScreen` | 프로젝트 목록 (홈) |
| `ProjectDetailScreen` | 프로젝트 상세 및 타임라인 |
| `ExperimentLogListScreen` | 실험 로그 목록/추가 |
| `HardwareIssueListScreen` | 하드웨어 이슈 목록/추가 |
| `LinkRepositoryScreen` | GitHub/GitLab 저장소 연동 |
| `GithubDashboardScreen` | GitHub 커밋/이슈/마일스톤 대시보드 |
| `GitlabDashboardScreen` | GitLab 커밋/이슈/마일스톤 대시보드 |
| `SettingsScreen` | 백엔드 URL, GitHub/GitLab 토큰 설정 |

---

## 프로젝트 구조

```
lib/
├── main.dart                  # 앱 진입점 (백엔드 URL 로드)
├── models/                    # 데이터 모델 (project, experiment_log, hardware_issue 등)
├── repositories/              # API 호출 추상화 레이어
├── screens/                   # 화면 위젯
├── services/
│   ├── api_client.dart        # HTTP 클라이언트 싱글톤 (에뮬레이터 자동 감지)
│   ├── github_service.dart    # GitHub API 연동
│   ├── gitlab_service.dart    # GitLab API 연동
│   └── settings_service.dart  # SharedPreferences 기반 설정 관리
└── utils/
    └── responsive_layout.dart # 반응형 레이아웃 유틸리티
```

---

## 로컬 실행

### 사전 준비

- Flutter SDK 3.41.4 이상 (`flutter --version` 확인)
- Android 에뮬레이터 또는 실제 기기 (Android 빌드 시)
- Android Studio / Android SDK

### 의존성 설치

```bash
flutter pub get
```

### Android 에뮬레이터 실행

```bash
# 사용 가능한 에뮬레이터 확인
flutter emulators

# 에뮬레이터 시작
flutter emulators --launch <emulator_id>

# 에뮬레이터 부팅 후 앱 실행
flutter run -d emulator-5554
```

### Windows 데스크탑 실행

```bash
flutter run -d windows
```

---

## 백엔드 연결 설정

앱 실행 시 백엔드 URL이 자동으로 결정됩니다.

| 환경 | 기본 URL |
|------|----------|
| Android 에뮬레이터 | `http://10.0.2.2:8000/api` |
| Windows / Linux 데스크탑 | `http://127.0.0.1:8000/api` |
| 운영 서버 (Synology NAS) | `https://rnd.hyunsu5203.synology.me/api` |

앱 내 **Settings 화면**에서 백엔드 URL을 직접 변경할 수 있습니다.
변경된 URL은 SharedPreferences에 저장되어 재실행 후에도 유지됩니다.

> 백엔드가 꺼져 있어도 앱은 실행됩니다. 연결 실패 시 헬스체크에서 오류를 표시합니다.

---

## GitHub / GitLab 연동

Settings 화면에서 토큰을 입력하면 대시보드에서 아래 정보를 조회할 수 있습니다.

- 최근 커밋 목록
- 오픈 이슈 목록
- 마일스톤 목록
- 팀 멤버 목록

---

## 검증

```bash
# 정적 분석
flutter analyze

# 테스트
flutter test
```

---

## 빌드 팁

- `flutter run` 최초 실행 시 Gradle 빌드로 1~2분 소요 (이후 캐시로 빠름)
- 코드 수정 후에는 `r` (Hot Reload) 또는 `R` (Hot Restart) 로 즉시 반영
- `build/` 디렉토리 삭제 시 전체 재빌드 필요 (`rm -rf build/`)
