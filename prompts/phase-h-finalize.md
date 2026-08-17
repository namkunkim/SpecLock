# Phase H — 문서 정리 + CI 등록

**목적**: 산출물을 저장소에 커밋 가능한 형태로 정리하고, 부패 감지 장치를 건다.
**주체**: AI 전담.

---

## 프롬프트

```
확정된 BR과 테스트를 최종 문서로 정리해줘.

산출물:

1. docs/spec/uc/UC-XXX-NN.md
   - templates/uc-template.md 형식 사용
   - 각 BR의 근거는 티켓 번호와 함께 한 문장 요약을 반드시 포함
   - Phase E에서 나온 상호 제약을 "상호 제약" 섹션에 채움
   - 상태를 오가는 UC라면 "상태 전이" 표를 채움. 단순 UC는 생략
   - 스레드·성능·환경 제약이 있으면 "비기능 제약"에 적음
   - 임계값·설정값은 파라미터 표로 분리
   - Phase E에서 보류된 항목은 "미명세 영역" 섹션에 명시
     빈 곳을 숨기지 않아야 다음 작업자와 AI가
     "여긴 아직 결정되지 않았다"를 알고 임의 판단하지 않는다

2. docs/spec/L0-overview.md 갱신
   - UC 목록 갱신
   - 이번 UC 작업 중 알게 된 도메인 개념 관계가 있으면
     "도메인 개념 관계" 섹션에 추가 (다이어그램이 아니라 텍스트로)
   - 모듈 밖 사정으로 설계가 정당화되는 것이 있으면
     "시스템 경계 밖 맥락"에 추가

3. docs/spec/scope.md 갱신 (있는 경우만)
   - Phase C에서 [경계] 섹션에 기록된 항목을
     "경계를 넘는 의존성" 표로 옮김
   - 이번 UC 작업 중 스코프 정의 자체가 바뀔 필요가 있으면
     (포함 대상 추가/제외) 사람 승인 후 반영

4. docs/spec/unknowns.md 에 출처 불명 항목 누적
   templates/unknowns.md 형식 사용

5. 정합성 검사 실행하여 확인
   저장소 루트에서 실행한다면 모듈 경로를 명시한다:
   Windows: scripts\check-spec.bat <module>\docs\spec\uc <module>\src\test
   그 외:   scripts/check-spec.sh <module>/docs/spec/uc <module>/src/test
   모듈 디렉터리 안에서 실행한다면 인자 없이 기본값을 그대로 쓴다.

6. 사이클 요약 (아래 형식)
```

---

## 사이클 요약 형식

Phase H 마지막에 항상 출력한다. 조직에 작업 가치를 설명할 근거가 된다.

```markdown
## UC-XXX-NN 사이클 요약

- 확정 BR: N개
- 발견한 불일치: N건
  - 문서 오류: N건
  - **코드 버그: N건**  ← 별도 이슈 등록
- **과거 이슈 중 이 테스트로 사전 검출 가능했던 건수: M / N건**
- 미명세로 남긴 영역: N개 (unknowns.md 참조)
- (측정했다면) mutation score: before X% → after Y%
```

굵게 표시한 두 지표가 가장 설득력 있다. "테스트 몇 개 썼습니다"보다 훨씬 강하다.

## CI 등록

`.github/workflows/spec-check.yml`을 그대로 쓰면 저장소 안의 모든
`*/docs/spec/uc`를 자동으로 찾아 모듈별로 검사한다. 모듈이 하나든
여러 개든 워크플로우 수정 없이 그대로 동작한다.

단일 모듈만 검사하는 최소 예시가 필요하면:

```yaml
- name: Spec-Test 정합성 검사
  run: ./scripts/check-spec.sh domain/docs/spec/uc domain/src/test
```

이 검사가 있어야 문서 부패가 조용히 진행되지 않는다.

- 문서에 BR을 추가하고 테스트를 안 쓰면 → 빌드 실패
- 문서에서 BR을 지우면 → 고아 테스트로 드러남

## CLAUDE.md 갱신

AI 에이전트가 이 구조를 인식하도록 프로젝트 루트에 다음을 추가한다.

```markdown
## 명세 구조

- `docs/spec/L0-overview.md` — 모듈 책임, 경계, UC 목록
- `docs/spec/uc/UC-*.md` — UC별 Business Rule (BR-XXX-NNN)
- `docs/spec/unknowns.md` — 근거 불명 조건 (판단 전 확인 필요)
- `test/spec/` — 각 BR의 검증 테스트 (@Spec으로 연결)

## 작업 규칙

1. 코드 변경 전 관련 UC 문서를 먼저 읽는다
2. `test/spec/` 전체가 통과해야 한다
3. 테스트가 실패하면 코드를 고친다.
   테스트나 spec을 고쳐서 통과시키지 않는다
4. `docs/spec/` 변경은 사람 승인이 필요하다. 필요하면 제안만 하고 멈춘다
5. "미명세 영역"에 해당하는 작업은 진행 전에 확인을 요청한다
```

3번과 4번이 실무에서 결정적이다. AI가 테스트 실패를 만나면 테스트를 고쳐서 통과시키는 것이 흔한 실패 모드다.

## 다음 UC

Phase B에서 정한 순서대로 다음 UC를 잡는다. **모듈 전체 커버는 목표가 아니다.** 신규 요구사항이 들어올 때마다 붙여나가는 방식으로 전환되면 성공이다.
