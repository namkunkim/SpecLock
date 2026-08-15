<#
.SYNOPSIS
    문서의 BR ID와 테스트의 @Spec ID 양방향 정합성 검사.

.DESCRIPTION
    이 검사가 CI에 있으면 문서 부패가 조용히 진행되지 않는다.
      - 문서에 BR을 추가하고 테스트를 안 쓰면  → 실패
      - 문서에서 BR을 지우면                  → 고아 테스트로 드러남

    문서에서는 정의부(**BR-XXX-NNN**)만 수집한다.
    본문 참조("BR-XXX-NNN 참조")는 정의가 아니므로 제외된다.

.PARAMETER SpecDir
    UC 문서 디렉터리. 기본값 spec/uc

.PARAMETER TestDir
    테스트 소스 디렉터리. 기본값 src/test

.EXAMPLE
    .\check-spec.ps1
    .\check-spec.ps1 -SpecDir spec\uc -TestDir app\src\test

.OUTPUTS
    종료 코드 0 = 정합, 1 = 불일치, 2 = 경로 오류
#>

param(
    [string]$SpecDir = "spec/uc",
    [string]$TestDir = "src/test"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SpecDir -PathType Container)) {
    Write-Host "spec 디렉터리 없음: $SpecDir" -ForegroundColor Red
    exit 2
}
if (-not (Test-Path -LiteralPath $TestDir -PathType Container)) {
    Write-Host "test 디렉터리 없음: $TestDir" -ForegroundColor Red
    exit 2
}

# ── 문서의 BR ID 수집 (정의부만) ──────────────────────────────
$docPattern = '\*\*(BR-[A-Z0-9]+-[0-9]+)\*\*'
$docIds = [System.Collections.Generic.SortedSet[string]]::new()

Get-ChildItem -LiteralPath $SpecDir -Recurse -Filter *.md -File | ForEach-Object {
    $content = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
    foreach ($m in [regex]::Matches($content, $docPattern)) {
        [void]$docIds.Add($m.Groups[1].Value)
    }
}

# ── 테스트의 @Spec ID 수집 (다중 인자 지원) ───────────────────
$specPattern = '@Spec\(([^)]*)\)'
$idPattern   = 'BR-[A-Z0-9]+-[0-9]+'
$testIds = [System.Collections.Generic.SortedSet[string]]::new()

Get-ChildItem -LiteralPath $TestDir -Recurse -File |
    Where-Object { $_.Extension -in '.kt', '.java', '.kts' } |
    ForEach-Object {
        $content = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
        foreach ($m in [regex]::Matches($content, $specPattern)) {
            foreach ($id in [regex]::Matches($m.Groups[1].Value, $idPattern)) {
                [void]$testIds.Add($id.Value)
            }
        }
    }

# ── 양방향 비교 ───────────────────────────────────────────────
$missing = @($docIds  | Where-Object { -not $testIds.Contains($_) })
$orphan  = @($testIds | Where-Object { -not $docIds.Contains($_)  })

$fail = $false

if ($missing.Count -gt 0) {
    Write-Host "테스트가 없는 BR:" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_" }
    Write-Host ""
    $fail = $true
}

if ($orphan.Count -gt 0) {
    Write-Host "문서에 정의되지 않은 @Spec ID:" -ForegroundColor Yellow
    $orphan | ForEach-Object { Write-Host "  - $_" }
    Write-Host ""
    $fail = $true
}

if ($fail) {
    Write-Host "정합성 실패 (문서 $($docIds.Count)개 / 테스트 $($testIds.Count)개)" -ForegroundColor Red
    exit 1
}

Write-Host "OK - BR $($docIds.Count)개, 모두 테스트로 검증됨" -ForegroundColor Green
exit 0
