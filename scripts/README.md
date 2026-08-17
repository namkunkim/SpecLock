# SpecLock 정합성 검사 스크립트

문서의 BR ID(`**BR-XXX-NNN**`)와 테스트의 `@Spec("BR-XXX-NNN")`을 양방향 대조한다.

이 검사가 있어야 문서 부패가 조용히 진행되지 않는다.

- 문서에 BR을 추가하고 테스트를 안 쓰면 → 실패
- 문서에서 BR을 지우면 → 고아 테스트로 드러남

## 파일

| 파일 | 환경 | 비고 |
|---|---|---|
| `check-spec.bat` | Windows | 더블클릭 가능. 내부에서 `.ps1` 호출 |
| `check-spec.ps1` | Windows / PowerShell Core | 실제 로직 |
| `check-spec.sh` | Linux / macOS / CI | bash |

세 파일 모두 동일한 판정과 종료 코드를 낸다.

## 사용법

`docs/spec/`는 저장소 루트가 아니라 **작업 중인 모듈 아래**에 생긴다.
경로는 항상 모듈 기준으로 지정한다 — 예: `domain` 모듈이면
`domain/docs/spec/uc`, `domain/src/test`.

**Windows**

```bat
scripts\check-spec.bat
scripts\check-spec.bat domain\docs\spec\uc domain\src\test
```

또는 PowerShell에서 직접:

```powershell
.\scripts\check-spec.ps1 -SpecDir domain\docs\spec\uc -TestDir domain\src\test
```

`.ps1` 실행이 정책으로 막혀 있으면 `.bat`을 쓰면 된다. 배치 래퍼가 `-ExecutionPolicy Bypass`로 호출하므로 전역 정책을 바꿀 필요가 없다.

**Linux / macOS**

```bash
chmod +x scripts/check-spec.sh
./scripts/check-spec.sh domain/docs/spec/uc domain/src/test
```

**모듈이 여럿일 때**

모듈마다 한 번씩 호출하거나, 저장소 안의 모든 `*/docs/spec/uc`를
자동으로 찾아 전부 검사한다. `.github/workflows/spec-check.yml`의
`spec-consistency` 잡이 이 방식으로 되어 있다.

```bash
while IFS= read -r spec_dir; do
  module_dir="${spec_dir%/docs/spec/uc}"
  ./scripts/check-spec.sh "$spec_dir" "$module_dir/src/test"
done < <(find . -type d -path '*/docs/spec/uc')
```

## 인자

| 위치 | 의미 | 기본값 |
|---|---|---|
| 1 | UC 문서 디렉터리 | `docs/spec/uc` (현재 디렉터리 기준) |
| 2 | 테스트 소스 디렉터리 | `src/test` (현재 디렉터리 기준) |

**기본값은 저장소 루트가 아니라 스크립트를 실행한 위치 기준이다.**
모듈 디렉터리 안에서 인자 없이 실행하면 그 모듈의 `docs/spec/uc`,
`src/test`를 본다. 저장소 루트에서 실행할 때는 대상 모듈 경로를
반드시 인자로 명시한다.

## 종료 코드

| 코드 | 의미 |
|---|---|
| 0 | 정합 |
| 1 | 불일치 (테스트 없는 BR 또는 고아 @Spec) |
| 2 | 경로 오류 |

## 수집 규칙

**문서** — `**BR-XXX-NNN**` 형태의 **정의부만** 수집한다. 본문의 참조(`BR-XXX-NNN 참조`)는 정의가 아니므로 제외된다. 따라서 UC 문서에서 BR을 정의할 때는 반드시 굵게 표기해야 한다.

```markdown
- **BR-EDIT-011**: 진입 시 리소스 존재를 확인한다     ← 수집됨
- BR-EDIT-012: 미확보 시 다운로드를 시작한다          ← 수집 안 됨
  근거: BR-EDIT-011 참조                            ← 수집 안 됨 (의도된 동작)
```

**테스트** — `@Spec(...)` 안의 모든 BR ID를 수집한다. 다중 인자를 지원한다.

```kotlin
@Spec("BR-EDIT-011")
@Spec("BR-EDIT-012", "BR-EDIT-013")   // 둘 다 수집됨
```

대상 확장자는 `.kt`, `.java`, `.kts`.

## 왜 순수 배치가 아닌가

`findstr`에는 `grep -o`에 해당하는 기능이 없어 **정규식으로 매치된 부분만 추출할 수 없다.** 이 작업은 ID 추출이 핵심이라 순수 배치로 구현하면 `for /f` + 문자열 절단으로 매우 취약해진다.

`check-spec.bat`은 실행 진입점 역할을 하고, 실제 처리는 PowerShell이 담당한다. Windows 7 이상에는 PowerShell이 기본 포함되어 있으므로 추가 설치는 필요 없다.

## CI

GitHub Actions 예시는 `.github/workflows/spec-check.yml` 참조. 저장소 안의
모든 `*/docs/spec/uc`를 자동으로 찾아 모듈별로 검사한다 — 모듈이 하나든
여러 개든 수정 없이 그대로 쓸 수 있다.

단일 모듈만 검사하고 싶다면 (Windows 러너 예시):

```yaml
- name: 정합성 검사 (domain 모듈)
  shell: pwsh
  run: .\scripts\check-spec.ps1 -SpecDir domain/docs/spec/uc -TestDir domain/src/test
```
