---
name: speclock
description: Extracts executable behavioral specs from legacy code by pairing each Business Rule (BR) with a verifying test, locked by ID so CI catches drift. Use for documenting legacy modules, reverse-engineering specs, characterization tests, pre-refactor safety nets, or specs for AI code generation. Applies even if only docs or only tests are requested.
---

# SpecLock

레거시 코드에서 **동작 명세(BR)와 그것을 검증하는 테스트를 한 세트로** 역추출하는 워크플로우.

## 절대 원칙

이 세 가지를 어기면 산출물의 가치가 사라진다. 작업 중 판단이 애매하면 여기로 돌아올 것.

1. **코드만 보고 BR을 확정하지 않는다.** 코드는 "무엇을 하는가"만 알려준다. "무엇을 해야 하는가"는 시장 이슈 이력, 기획 문서, git 이력에 있다. 코드만 근거인 항목은 현재 버그를 정식 명세로 승격시킬 위험이 있으므로 반드시 보류로 분류한다.
2. **Phase E와 G에서는 반드시 멈추고 사람에게 확인받는다.** 이 두 곳은 "이게 의도인가 버그인가"를 판단하는 지점이고, 코드에 없는 정보가 필요하다. 자동으로 통과시키면 검증되지 않은 명세가 커밋된다.
3. **테스트가 실패해도 코드를 고치지 않는다.** 이 워크플로우에서 테스트 실패는 고쳐야 할 문제가 아니라 **발견해야 할 성과**다. 문서가 틀렸거나 실제 버그이거나 둘 중 하나이고, 어느 쪽인지 판단하는 것이 작업의 목적이다.

## 산출물 구조

```
<module>/
├── docs/spec/
│   ├── scope.md                 명세 범위 정의 (비연속 스코프일 때만)
│   ├── L0-overview.md          모듈 책임·경계·UC 목록 (스코프당 1개)
│   ├── uc/UC-<약어>-NN.md       UC별 BR 목록 (UC당 1개)
│   └── unknowns.md             출처 불명 조건 누적 목록
└── test/spec/
    └── <UC>SpecTest.kt         @Spec("BR-...") 로 문서와 결속
```

UC 하나의 산출물은 **문서 A4 1장 + 테스트 파일 1개** 규모다. 이보다 커지면 UC를 쪼갤 신호다.

명세 대상이 패키지나 모듈 하나로 응집되지 않고 **특정 클래스 + 명시된 여러 패키지** 같은 비연속 범위라면, Phase A 전에 `scope.md`로 범위와 경계를 먼저 선언한다. 단일 모듈이면 생략한다. 자세한 판단은 `prompts/phase-a-uc-discovery.md`의 A-0 참조.

## Phase 실행

각 Phase는 `prompts/` 아래에 상세 지시가 있다. 해당 Phase를 시작할 때 그 파일을 읽고 따를 것.

| Phase | 내용 | 지시 파일 |
|---|---|---|
| A | 모듈 스캔 → UC 후보 도출 | `prompts/phase-a-uc-discovery.md` |
| B | 우선순위 결정, 첫 UC 선정 | `prompts/phase-b-prioritize.md` |
| C | 분기·조건 추출 | `prompts/phase-c-branch-extract.md` |
| D | 외부 소스 대조 | `prompts/phase-d-cross-reference.md` |
| **E** | **BR 확정 — 사람 승인 대기** | `prompts/phase-e-br-draft.md` |
| F | 테스트 작성 | `prompts/phase-f-test-write.md` |
| **G** | **실행 → 불일치 분석 — 사람 판단 대기** | `prompts/phase-g-run-analyze.md` |
| H | 문서 정리 + CI 등록 | `prompts/phase-h-finalize.md` |

명세 구축 이후 신규 요구사항이 들어왔을 때는 `prompts/ongoing-new-requirement.md`를 따른다. 역추출이 아니라 정방향 사용이다.

## 판단 기준

- **BR인가 아닌가** → `docs/br-criteria.md`. 싱글톤·세부 조건·임계값·예외 경로·리소스 선행조건 사례별 판정이 있다. Phase E에서 반드시 읽을 것.
- **테스트 작성 규칙** → `docs/test-rules.md`. 어서션 대상, Fake 패턴, 비동기 처리. Phase F에서 반드시 읽을 것.
- **조직 도입·범위·기존 테스트 처리** → `docs/adoption.md`. 기존 테스트를 만났을 때의 처리 방침이 여기 있다.

## 템플릿

- `templates/scope.md` — 명세 범위 정의 (비연속 스코프일 때만 사용)
- `templates/L0-overview.md` — 모듈 조망 문서
- `templates/uc-template.md` — UC별 BR 문서
- `templates/unknowns.md` — 출처 불명 조건 누적
- `templates/spec-test-template.kt` — 테스트 파일

두 템플릿에는 BR을 "잘 이해하기" 위한 섹션이 포함되어 있다.
채우는 것을 건너뛰지 말 것.

- UC 문서의 **근거**: 티켓 번호만 적지 않고 한 문장 요약을 남긴다
- UC 문서의 **반사실**: 더 단순한 대안을 왜 안 썼는지
- UC 문서의 **상호 제약**: BR 사이의 충돌·의존 관계
- UC 문서의 **상태 전이**: 상태를 오가는 UC의 흐름
- UC 문서의 **비기능 제약**: 스레드·성능·환경 제약
- L0 문서의 **시스템 경계 밖 맥락**: 모듈 밖 사정이 설계를 정당화하는 경우
- L0 문서의 **도메인 개념 관계**: 개념 간 관계 (다이어그램 대신 텍스트로)

## 스크립트

정합성 검사는 `scripts/` 아래에 세 가지 형태로 있고 동일하게 동작한다.
Windows는 `check-spec.bat`, 그 외는 `check-spec.sh`. 사용법은 `scripts/README.md` 참조.

## 범위

**모듈 전체 커버는 목표가 아니다.** 신규 요구사항이 들어올 때마다 해당 영역을 붙여나가는 습관으로 정착시키는 것이 목표다.

- L0는 모듈 전체를 얕게, 지금 작성한다
- UC별 BR은 우선순위 순으로 점진 확대한다
- 대상 UC에 해당하는 코드만 읽는다. 모듈 전체를 스캔하고 시작하려 하면 착수 자체를 못 한다

명세가 없는 영역은 "미명세이므로 변경 전 확인 요청"으로 처리하면 된다. 부분 커버리지로도 충분히 작동한다.
