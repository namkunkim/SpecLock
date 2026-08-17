#!/usr/bin/env bash
#
# 문서의 BR ID와 테스트의 @Spec ID 양방향 정합성 검사.
#
# 이 검사가 CI에 있으면 문서 부패가 조용히 진행되지 않는다.
#   - 문서에 BR을 추가하고 테스트를 안 쓰면 빌드 실패
#   - 문서에서 BR을 지우면 고아 테스트가 드러남
#
# 사용법: ./check-spec.sh [spec_dir] [test_dir]
#
# docs/spec/ 은 저장소 루트가 아니라 모듈 아래에 생긴다.
# 예: domain 모듈이면 ./check-spec.sh domain/docs/spec/uc domain/src/test
# 인자를 생략하면 현재 디렉터리 기준 docs/spec/uc, src/test 를 본다.

set -uo pipefail

SPEC_DIR="${1:-docs/spec/uc}"
TEST_DIR="${2:-src/test}"

[ -d "$SPEC_DIR" ] || { echo "spec 디렉터리 없음: $SPEC_DIR"; exit 1; }
[ -d "$TEST_DIR" ] || { echo "test 디렉터리 없음: $TEST_DIR"; exit 1; }

# 문서의 BR ID — 정의부(**BR-XXX-NNN**)만 수집.
# 본문 참조("BR-...-014 참조")는 정의가 아니므로 제외한다.
DOC_IDS=$(grep -rhoE '\*\*BR-[A-Z0-9]+-[0-9]+\*\*' "$SPEC_DIR" \
          | tr -d '*' | sort -u)

# 테스트의 @Spec ID — @Spec("A", "B") 다중 인자 지원
TEST_IDS=$(grep -rhoE '@Spec\([^)]*\)' "$TEST_DIR" \
           | grep -oE 'BR-[A-Z0-9]+-[0-9]+' | sort -u)

MISSING=$(comm -23 <(echo "$DOC_IDS") <(echo "$TEST_IDS"))
ORPHAN=$(comm -13 <(echo "$DOC_IDS") <(echo "$TEST_IDS"))

FAIL=0

if [ -n "$MISSING" ]; then
    echo "테스트가 없는 BR:"
    echo "$MISSING" | sed 's/^/  - /'
    echo
    FAIL=1
fi

if [ -n "$ORPHAN" ]; then
    echo "문서에 정의되지 않은 @Spec ID:"
    echo "$ORPHAN" | sed 's/^/  - /'
    echo
    FAIL=1
fi

DOC_COUNT=$(echo "$DOC_IDS" | grep -c . || true)
TEST_COUNT=$(echo "$TEST_IDS" | grep -c . || true)

if [ "$FAIL" -eq 0 ]; then
    echo "OK — BR ${DOC_COUNT}개, 모두 테스트로 검증됨"
else
    echo "정합성 실패 (문서 ${DOC_COUNT}개 / 테스트 ${TEST_COUNT}개)"
fi

exit "$FAIL"
