# SpecLock

> 동작 명세 기반 회귀 검증 체계

레거시 코드에서 **동작 명세(Business Rule)와 그것을 검증하는 테스트를 한 세트로** 역추출하고, **BR ID로 결속해 CI가 그 결속을 강제**하게 만드는 워크플로우.

이름은 lockfile에서 왔다. 현재 보장되는 동작을 잠가두고, 바꾸려면 명시적으로 갱신해야 하며, 몰래 바뀌면 빌드가 깨진다. BR ID가 하는 일이 정확히 그것이다.

AI 에이전트(Claude Code 등)와 함께 쓰도록 설계되었으며, 저장소 자체가 Claude 스킬로도 설치된다.

---

## 무엇을 해결하는가

레거시 모듈에는 "반드시 지켜져야 하는 동작"이 코드 안에 암묵적으로만 존재한다. 문서에도 없고 테스트도 그것을 검증하지 않는다. 그래서 리팩토링이나 AI 코드 생성이 그 동작을 소리 없이 깨뜨리고, 시장에서 발견된다.

AI 코드 생성이 본격화되면 이 문제는 **더 심해진다.** 사람보다 훨씬 빠른 속도로 코드가 바뀌는데 검증 하네스가 없기 때문이다.

이 워크플로우는 암묵적 동작을 **BR(Business Rule)** 이라는 검증 가능한 단위로 꺼내고, 각 BR에 테스트를 붙여 CI가 정합성을 강제하게 만든다. 결과적으로 문서와 테스트가 같이 늙는다.

배경과 설계 근거는 [docs/why.md](docs/why.md) 참조.

## 산출물

```
<module>/
├── spec/
│   ├── L0-overview.md          모듈 책임·경계·UC 목록
│   ├── uc/UC-<약어>-NN.md       UC별 BR 목록
│   └── unknowns.md             출처 불명 조건 누적
└── test/spec/
    └── <UC>SpecTest.kt         @Spec("BR-...") 로 문서와 결속
```

BR ID가 문서와 테스트를 잇고, CI가 양방향 정합성을 검사한다. 문서에 BR을 추가하고 테스트를 안 쓰면 빌드가 깨진다.

UC 하나의 산출물은 **문서 A4 1장 + 테스트 파일 1개** 규모다.

## 프로세스

| Phase | 내용 | 주체 | 프롬프트 |
|---|---|---|---|
| A | 모듈 스캔 → UC 후보 도출 | AI 주도, 사람 컨펌 | [phase-a](prompts/phase-a-uc-discovery.md) |
| B | 우선순위 결정, 첫 UC 선정 | AI 제안, 사람 결정 | [phase-b](prompts/phase-b-prioritize.md) |
| C | 분기·조건 추출 | AI 전담 | [phase-c](prompts/phase-c-branch-extract.md) |
| D | 외부 소스 대조 | AI 전담 | [phase-d](prompts/phase-d-cross-reference.md) |
| **E** | **BR 확정** | **사람 판단 필수** | [phase-e](prompts/phase-e-br-draft.md) |
| F | 테스트 작성 | AI 전담 | [phase-f](prompts/phase-f-test-write.md) |
| **G** | **기존 코드에 실행 → 불일치 분석** | **사람 판단 필수** | [phase-g](prompts/phase-g-run-analyze.md) |
| H | 문서 정리 + CI 등록 | AI 전담 | [phase-h](prompts/phase-h-finalize.md) |

명세 구축 이후 신규 요구사항 처리는 [prompts/ongoing-new-requirement.md](prompts/ongoing-new-requirement.md).

사람이 붙는 지점은 E와 G 두 곳뿐이다. UC 하나당 사람 작업량은 4~5시간 정도.

## 절대 원칙

이 셋을 어기면 산출물의 가치가 사라진다.

1. **코드만 보고 BR을 확정하지 않는다.** 코드는 "무엇을 하는가"만 알려준다. "무엇을 해야 하는가"는 이슈 이력·기획 문서·git 이력에 있다. 코드만 근거인 항목은 현재 버그를 정식 명세로 승격시킬 위험이 있다.
2. **Phase E와 G에서 멈추고 사람에게 확인받는다.** 이 두 곳은 코드에 없는 정보가 필요한 지점이다.
3. **테스트가 실패해도 코드를 고치지 않는다.** 이 워크플로우에서 테스트 실패는 고칠 문제가 아니라 **발견해야 할 성과**다.

## 시작하기

### 1. Claude 스킬로 설치 (권장)

```bash
git clone <this-repo> ~/.claude/skills/speclock
```

`SKILL.md`가 진입점이다. 레거시 문서화·스펙 역추출·특성화 테스트 요청에 자동 트리거된다.

### 2. 프롬프트만 복사해서 사용

`prompts/` 안의 파일을 그대로 붙여넣어도 된다. 스킬 설치 없이 어떤 AI 도구에서든 쓸 수 있다.

### 3. CI 검사 등록

Windows:

```bat
scripts\check-spec.bat spec\uc src\test
```

Linux / macOS:

```bash
chmod +x scripts/check-spec.sh
./scripts/check-spec.sh spec/uc src/test
```

세 스크립트(`.bat` / `.ps1` / `.sh`)가 동일한 판정과 종료 코드를 낸다. 상세는 [scripts/README.md](scripts/README.md).

GitHub Actions 워크플로우 예시는 [.github/workflows/spec-check.yml](.github/workflows/spec-check.yml).

### 4. @Spec 어노테이션 추가

```kotlin
@Target(AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.SOURCE)
annotation class Spec(vararg val ids: String)
```

## 문서

- [docs/why.md](docs/why.md) — 배경과 설계 근거
- [docs/br-criteria.md](docs/br-criteria.md) — BR 판별 기준, 사례별 판정
- [docs/test-rules.md](docs/test-rules.md) — 테스트 작성 규칙
- [docs/adoption.md](docs/adoption.md) — 조직 도입 전략, 범위 설정, 기존 테스트 처리

## 범위에 대하여

**모듈 전체 커버는 목표가 아니다.** 이 작업은 끝내는 프로젝트가 아니라, 신규 요구사항이 들어올 때마다 해당 영역을 붙여나가는 습관이다.

- L0는 모듈 전체를 얕게, 지금 작성한다 (A4 2~3장)
- UC별 BR은 우선순위 순으로 점진 확대한다
- 명세가 없는 영역은 AI에게 "미명세이므로 변경 전 확인 요청"으로 알린다

부분 커버리지로도 충분히 작동한다.
