# 예약 알리미 (Reservation Reminder)

시설(강당·강의실 등) 사용 날짜를 등록하면, 시설별 예약 규칙에 따라 **예약해야 하는 날짜를
자동 계산**하고 그 시점에 **로컬 알림**을 주는 개인용 모바일 앱입니다.

- 서버 없음 · 계정 없음 · 외부 연동 없음 (**Local-first**)
- Android / iOS (Flutter 단일 코드베이스)
- 설계 근거: [`mobile_reservation_notification_plan.md`](mobile_reservation_notification_plan.md)

---

## 기술 스택

| 영역 | 기술 |
|---|---|
| 프레임워크 / 언어 | Flutter / Dart |
| 상태 관리 | Riverpod |
| 로컬 DB | SQLite + Drift |
| 로컬 알림 | flutter_local_notifications + timezone |
| 달력 | table_calendar |

---

## 프로젝트 구조

```
lib/
├── main.dart / app.dart          진입점, 테마, 라우팅
├── core/                         상수 · 날짜 유틸 · 포맷 · 테마
├── domain/
│   ├── models/                   순수 도메인 모델 + enum (codegen 불필요)
│   └── services/                 ★핵심 로직 (단위 테스트 대상)
│       ├── rule_engine.dart          N일 전 규칙 계산
│       ├── schedule_generator.dart   스케줄 생성 + 지난 스케줄 판정
│       ├── conflict_validator.dart   충돌 검증
│       └── recurrence_generator.dart 반복(N일/요일) 생성
├── data/
│   ├── database/                 Drift 테이블 · DAO · DB (migration)
│   └── repositories/             행 ↔ 도메인 매핑 + 저장소
├── application/
│   ├── reservation_service.dart  전체 흐름 조율(등록/삭제/알림)
│   └── providers.dart            Riverpod 배선
├── notifications/                NotificationManager (등록/취소/동기화)
└── features/                     UI (달력/일정등록/반복/시설관리/설정)
```

계획서 20장 아키텍처를 그대로 반영합니다:
`UI → ReservationService → (RuleEngine/ScheduleGenerator/ConflictValidator) → Repository → SQLite → NotificationManager`

---

## 처음 실행하기

> 이 저장소에는 `lib/`(앱 코드)와 `test/`만 들어 있습니다.
> Android/iOS 네이티브 폴더와 Drift 생성 코드는 **로컬에서 생성**해야 합니다.

### 1. Flutter 설치 확인
```bash
flutter --version   # Flutter 3.19+ / Dart 3.3+
flutter doctor
```

### 2. 플랫폼 폴더 생성 (android/ios/)
이 폴더들은 `.gitignore` 대상이 아니지만 저장소에 포함되지 않았습니다.
프로젝트 루트에서 아래를 실행하면 `lib/`를 유지한 채 네이티브 폴더가 생성됩니다.
```bash
flutter create --org com.example --project-name reservation_reminder .
```

### 3. 패키지 설치
```bash
flutter pub get
```

### 4. Drift 코드 생성 (`*.g.dart`)
Drift 는 빌드 타임 코드 생성을 사용합니다. **최초 1회 + 스키마 변경 시** 실행:
```bash
dart run build_runner build --delete-conflicting-outputs
```
개발 중 자동 감시:
```bash
dart run build_runner watch --delete-conflicting-outputs
```

### 5. 실행
```bash
flutter run
```

---

## 알림을 위한 플랫폼 설정

`flutter create` 로 생성된 네이티브 프로젝트에 아래를 추가해야 실기기 알림이 정상 동작합니다.

### Android — `android/app/src/main/AndroidManifest.xml`
`<manifest>` 안에 권한 추가:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```
`<application>` 안에 재부팅/알림 수신 리시버 추가:
```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
    <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
  </intent-filter>
</receiver>
```
`android/app/build.gradle` 에서 `minSdkVersion 21` 이상, `coreLibraryDesugaringEnabled true` 설정
(정확한 설정은 flutter_local_notifications README 참고).

### iOS — `ios/Runner/AppDelegate.swift`
`didFinishLaunchingWithOptions` 안에 추가:
```swift
if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
}
```
`ios/Runner/Info.plist` 에 백그라운드 모드가 필요하면 추가 설정. iOS 배포에는
Apple 개발자 계정 + 서명이 필요합니다.

---

## 테스트

핵심 도메인 로직은 codegen 없이 바로 테스트할 수 있습니다:
```bash
flutter test
```
포함된 테스트:
- `rule_engine_test` — N일 전 규칙 (예: 09/20 → 09/13, 09/17)
- `schedule_generator_test` — 스케줄 병합 + 지난 스케줄 알림 제외
- `conflict_validator_test` — 동일 시설·동일 날짜 충돌
- `recurrence_generator_test` — N일마다 / 특정 요일
- `date_utils_test` — 날짜 경계 계산

---

## 빌드 (Release)

Android APK:
```bash
flutter build apk --release
```
iOS (Mac 필요):
```bash
flutter build ios --release
```

---

## MVP 범위에서 제외된 것 (계획서 25장)

서버 · 로그인 · 외부 예약 연동 · 클라우드 동기화 · 백업/복원 ·
주말/공휴일 처리 · 기존 일정 규칙 재계산 · 완료 버튼 · DB 암호화 · 앱 잠금.

## 알림 안정성(계획서 9·15장)

앱 시작 시 DB의 미래 일정과 OS 알림을 동기화합니다(`ReservationService.syncNotificationsOnStartup`).
재부팅·절전·권한 변경·지연/누락 등 **실기기 안정성 검증은 별도 테스트 단계**에서 진행해야 하며,
이는 시뮬레이터/에뮬레이터가 아닌 실제 단말에서만 확인됩니다.
