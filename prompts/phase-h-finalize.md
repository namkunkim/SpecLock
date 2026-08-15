# Phase H — 문서 정리 + CI 등록

**목적**: 산출물을 저장소에 커밋 가능한 형태로 정리하고, 부패 감지 장치를 건다.
**주체**: AI 전담.

---

## 프롬프트

```
확정된 BR과 테스트를 최종 문서로 정리해줘.

산출물:

1. spec/uc/UC-XXX-NN.md
   - templates/uc-template.md 형식 사용
   - 근거가 이슈인 BR은 이슈 번호 병기
   - 임계값·설정값은 파라미터 표로 분리
   - Phase E에서 보류된 항목은 "미명세 영역" 섹션에 명시
     빈 곳을 숨기지 않아야 다음 작업자와 AI가
     "여긴 아직 결정되지 않았다"를 알고 임의 판단하지 않는다

2. spec/L0-overview.md 의 UC 목록 갱신

3. spec/unknowns.md 에 출처 불명 항목 누적
   templates/unknowns.md 형식 사용

4. 정합성 검사 실행하여 확인
   Windows: scripts\check-spec.bat / 그 외: scripts/check-spec.sh

5. 사이클 요약 (아래 형식)
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

```yaml
# .github/workflows/spec-check.yml
- name: Spec-Test 정합성 검사
  run: ./scripts/check-spec.sh spec/uc src/test
```

이 검사가 있어야 문서 부패가 조용히 진행되지 않는다.

- 문서에 BR을 추가하고 테스트를 안 쓰면 → 빌드 실패
- 문서에서 BR을 지우면 → 고아 테스트로 드러남

## CLAUDE.md 갱신

AI 에이전트가 이 구조를 인식하도록 프로젝트 루트에 다음을 추가한다.

```markdown
## 명세 구조

- `spec/L0-overview.md` — 모듈 책임, 경계, UC 목록
- `spec/uc/UC-*.md` — UC별 Business Rule (BR-XXX-NNN)
- `spec/unknowns.md` — 근거 불명 조건 (판단 전 확인 필요)
- `test/spec/` — 각 BR의 검증 테스트 (@Spec으로 연결)

## 작업 규칙

1. 코드 변경 전 관련 UC 문서를 먼저 읽는다
2. `test/spec/` 전체가 통과해야 한다
3. 테스트가 실패하면 코드를 고친다.
   테스트나 spec을 고쳐서 통과시키지 않는다
4. `spec/` 변경은 사람 승인이 필요하다. 필요하면 제안만 하고 멈춘다
5. "미명세 영역"에 해당하는 작업은 진행 전에 확인을 요청한다
```

3번과 4번이 실무에서 결정적이다. AI가 테스트 실패를 만나면 테스트를 고쳐서 통과시키는 것이 흔한 실패 모드다.

## 다음 UC

Phase B에서 정한 순서대로 다음 UC를 잡는다. **모듈 전체 커버는 목표가 아니다.** 신규 요구사항이 들어올 때마다 붙여나가는 방식으로 전환되면 성공이다.
