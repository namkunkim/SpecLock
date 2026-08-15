# BR 테스트 작성 규칙

Phase F에서 참조한다. 목표는 **구현을 리팩토링해도 살아남고, 실패 시 어느 BR이 깨졌는지 즉시 알 수 있는 테스트**다.

## 왜 이 규칙들이 필요한가

기존 레거시 테스트가 무의미해지는 전형적 원인은 두 가지다. 커버리지 숫자를 올리려고 **코드를 실행만 하고 검증하지 않는 것**, 그리고 **구현 세부를 검증해서 리팩토링을 방해하는 것**. 아래 규칙은 이 둘을 방지한다.

## 1. 이름 = BR 문장

```kotlin
@Spec("BR-EDIT-012")
@Test
fun `리소스가 없으면 편집을 활성화하지 않고 다운로드를 시작한다`() { ... }
```

테스트 목록을 뽑으면 그것이 명세 목록이 된다. 이것이 "실행 가능한 명세"의 실체다.

`test_case_01`, `testEnterEdit` 같은 이름은 금지. 이름만 보고 무엇을 보장하는지 알 수 없으면 명세로 기능하지 못한다.

## 2. @Spec 어노테이션 필수

문서와 테스트를 잇는 유일한 연결고리이며, CI 정합성 검사의 대상이다. 누락되면 그 테스트는 명세 체계 밖에 있는 것이다.

```kotlin
@Target(AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.SOURCE)
annotation class Spec(vararg val ids: String)
```

## 3. 어서션은 관측 가능한 결과만

| 검증 대상 | 판정 |
|---|---|
| ViewModel state / UI state | OK |
| 반환값 | OK |
| 외부로 나간 요청의 발생 여부·내용 | OK |
| 저장된 데이터의 최종 상태 | OK |
| 인스턴스 동일성 (`assertSame`) | 금지 |
| private 필드 / 내부 컬렉션 크기 | 금지 |
| 메서드 호출 순서 | 금지 |
| 특정 클래스 타입 여부 | 원칙적 금지 |

내부를 검증하면 구조를 바꿀 때마다 테스트가 깨진다. 그러면 테스트가 안전망이 아니라 **변경의 방해물**이 되고, 결국 아무도 신뢰하지 않게 된다.

## 4. mock verify 대신 Fake

```kotlin
// 지양 — 호출 여부만 확인. 구현 결합도 높음
verify(repo).download(FILTER_PACK)

// 권장 — 상태 확인. 어떻게 호출했든 결과가 같으면 통과
assertTrue(repo.downloadStarted(FILTER_PACK))
```

Fake는 **결과를 관측 가능하게 만드는 최소한의 실제 구현**이다. 리팩토링으로 호출 방식이 바뀌어도 결과가 같으면 살아남는다.

```kotlin
class FakeResourceRepo(
    private var available: MutableSet<ResourceId> = mutableSetOf(),
) : ResourceRepository {

    private val started = mutableSetOf<ResourceId>()
    private val progress = MutableStateFlow<Progress?>(null)

    override fun has(id: ResourceId) = id in available
    override fun download(id: ResourceId) { started += id }
    override fun observe(id: ResourceId) = progress.filterNotNull()

    // 검증용 질의
    fun downloadStarted(id: ResourceId) = id in started

    // 시나리오 조작
    fun emitProgress(percent: Int) { progress.value = Progress.Running(percent) }
    fun emitFailure(e: Throwable) { progress.value = Progress.Failed(e) }
    fun emitComplete(id: ResourceId) { available += id; progress.value = Progress.Done }
}
```

Fake는 UC 간 재사용된다. 새로 만들기 전에 기존 것을 먼저 찾는다.

## 5. BR 1개 = 테스트 1개 (병합 금지)

조건이 복수인 BR은 테스트를 나눠도 된다:

```kotlin
@Spec("BR-EDIT-015")
@Test fun `실패 시 화면을 종료하지 않는다`() { ... }

@Spec("BR-EDIT-015")
@Test fun `실패 시 재시도 수단을 제공한다`() { ... }
```

반대는 금지한다. 테스트 하나가 여러 BR을 검증하면 실패했을 때 어느 규칙이 깨졌는지 알 수 없고, ID 결속의 의미가 사라진다.

## 6. 구조

Given-When-Then을 따르되 주석으로 표시하지 않는다. 빈 줄로 구분하면 충분하다.

```kotlin
@Spec("BR-EDIT-014")
@Test
fun `초기 설정이 완료되었어도 리소스가 삭제되었으면 다시 확인한다`() {
    val repo = FakeResourceRepo(available = mutableSetOf())
    val vm = EditViewModel(repo, oobeCompleted = true)

    vm.enter(EditFeature.FILTER)

    assertTrue(repo.downloadStarted(FILTER_PACK))
}
```

셋업이 5줄을 넘으면 픽스처 빌더로 뺀다. 테스트 본문에서 **무엇을 검증하는지가 한눈에 보여야** 명세로 기능한다.

## 7. 비동기 처리

코루틴/Flow는 가상 시간으로 제어한다. 실제 지연을 기다리면 테스트가 느려지고 불안정해진다.

```kotlin
@Test
fun `타임아웃 후 대체 경로로 전환한다`() = runTest {
    val repo = FakeResourceRepo(available = mutableSetOf())
    val vm = EditViewModel(repo)

    vm.enter(EditFeature.FILTER)
    advanceTimeBy(TIMEOUT + 1.seconds)

    assertTrue(vm.state.value.usingFallback)
}
```

타임아웃 상수는 테스트에 숫자를 박지 말고 프로덕션 상수를 참조한다. 정책 변경 시 테스트가 따라간다.

## 8. 기존 코드에 돌려보는 것이 목적이다

Phase G에서 이 테스트들은 **기존 코드에 대해** 실행된다. 그러므로:

- 새 설계를 전제한 API를 가정하지 않는다
- 존재하지 않는 클래스나 메서드를 쓰지 않는다
- 현재 구조에서 테스트가 불가능하다면, 그것 자체가 보고할 발견이다. 억지로 코드를 고쳐서 테스트 가능하게 만들지 않는다

이 워크플로우에서 테스트 실패는 고칠 문제가 아니라 **찾아낸 성과**다.

## 자체 점검

작성 후 각 테스트에 대해 확인한다:

- [ ] 구현을 리팩토링해도 살아남는가?
- [ ] 실패하면 어느 BR이 깨졌는지 즉시 알 수 있는가?
- [ ] 이름만 읽고 무엇을 보장하는지 이해되는가?
- [ ] 기존 코드에 그대로 실행 가능한가?
- [ ] 프로덕션 코드에 테스트용 코드를 추가하지 않았는가?
