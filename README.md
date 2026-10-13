# stock_app — 주식 분석 앱 (Flutter 클라이언트)

`stock_system`(파이썬 백엔드)이 계산한 포트폴리오·ETF·실적 분석 결과를 보여주는 Flutter 앱.

> **로컬 디스크 정리를 위한 아카이브** (2026-10-13 기준).
> 원본 경로: `~/PycharmProjects/stock_app/` — 로컬 삭제됨. 소스는 이 저장소에 전부 올라와 있다.

백엔드(비공개 저장소): `haakon0904-source/stock-system` — KIS OpenAPI 연동, 카카오 알림, `api_server.py` 가 이 앱의 API.

## 구조

```
lib/
  main.dart
  models/     데이터 모델
  services/   API 호출
  screens/    화면
  widgets/    공통 위젯
```

주요 패키지: `http`, `provider`, `fl_chart`(차트), `shared_preferences`, `cached_network_image`, `shimmer`, `intl`.

## 실행

```bash
flutter pub get
flutter run            # 기기/에뮬레이터
flutter build apk      # 또는 flutter build web
```

`build/`, `.dart_tool/` 는 저장소에서 제외되어 있다 (`flutter pub get` 이후 자동 재생성).
