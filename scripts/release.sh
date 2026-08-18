#!/usr/bin/env bash
# 예약 알리미 배포 스크립트
# - pubspec 버전 증가(빌드번호 +1, 인자 주면 사용자 버전도 변경)
# - release APK 빌드
# - 배포본을 "예약알리미.apk" 로 고정 복사
# - RELEASE.md 의 최신 버전/이력 갱신
#
# 사용법:
#   bash scripts/release.sh          # 빌드번호만 +1
#   bash scripts/release.sh 1.1.0    # 사용자 버전을 1.1.0 으로 변경 + 빌드번호 +1
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

# ---- 툴체인 경로 (이 PC 기준, 필요 시 환경변수로 덮어쓰기) ----
FL="${FLUTTER_BIN:-/home/user/snap/flutter/common/flutter/bin/flutter}"
export JAVA_HOME="${JAVA_HOME:-/home/user/jdk-17.0.20+8}"
export ANDROID_HOME="${ANDROID_HOME:-/home/user/Android/sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/rr-xdg}"
mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null || true

if [ ! -x "$FL" ]; then
  FL="$(command -v flutter || true)"
fi
[ -n "$FL" ] || { echo "flutter 를 찾을 수 없습니다. FLUTTER_BIN 을 지정하세요."; exit 1; }

# ---- 현재 버전 파싱: version: A.B.C+N ----
cur_line="$(grep -E '^version:' pubspec.yaml | head -1)"
cur="${cur_line#version:}"; cur="$(echo "$cur" | tr -d ' ')"
name="${cur%%+*}"      # A.B.C
build="${cur##*+}"     # N
[ "$build" = "$cur" ] && build=0

new_name="${1:-$name}"
new_build=$((build + 1))
new_version="${new_name}+${new_build}"

echo "버전: ${cur}  ->  ${new_version}"
# pubspec 갱신
sed -i -E "s/^version:.*/version: ${new_version}/" pubspec.yaml

# ---- 빌드 ----
"$FL" pub get
"$FL" build apk --release

# ---- 배포본 이름 고정 ----
cp build/app/outputs/flutter-apk/app-release.apk "예약알리미.apk"
echo "배포본: ${ROOT}/예약알리미.apk (${new_version})"

# ---- RELEASE.md 갱신 ----
today="$(date +%Y-%m-%d)"
summary="${RELEASE_NOTE:-빌드}"
# 현재 최신 버전 블록 교체
python3 - "$new_name" "$new_build" "$today" "$summary" <<'PY'
import re, sys
name, build, today, summary = sys.argv[1:5]
p = "RELEASE.md"
s = open(p, encoding="utf-8").read()
s = re.sub(r"- \*\*v[^\n]*\n- 파일: `예약알리미\.apk`",
           f"- **v{name} (빌드 {build})** — {today}\n- 파일: `예약알리미.apk`", s, count=1)
row = f"| v{name} | {build} | {today} | {summary} |"
s = s.replace("| 버전 | 빌드 | 날짜 | 요약 |\n|---|---|---|---|\n",
              f"| 버전 | 빌드 | 날짜 | 요약 |\n|---|---|---|---|\n{row}\n", 1)
open(p, "w", encoding="utf-8").write(s)
print("RELEASE.md 갱신 완료")
PY

echo "완료: v${new_name} (빌드 ${new_build})"
