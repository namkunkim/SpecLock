package <module>.spec

import kotlin.test.*
import kotlinx.coroutines.test.*

/**
 * UC-<약어>-NN: <제목>
 *
 * 명세: spec/uc/UC-<약어>-NN.md
 *
 * 이 파일의 테스트는 기존 코드에 대해 실행되어 명세와 실제 동작의 일치를 확인한다.
 * 실패는 고쳐야 할 문제가 아니라 분석해야 할 발견이다.
 */
class <UC명>SpecTest {

    // ── 진입 시 확인 ────────────────────────────────────────

    @Spec("BR-<약어>-011")
    @Test
    fun `<BR 문장 그대로>`() {
        val repo = Fake<X>Repo(/* 초기 상태 */)
        val sut = <SUT>(repo)

        sut.<행위>()

        assertTrue(repo.<관측 가능한 결과>())
    }

    // ── 미확보 시 동작 ──────────────────────────────────────

    @Spec("BR-<약어>-012")
    @Test
    fun `<BR 문장 그대로>`() {
        val repo = Fake<X>Repo()
        val sut = <SUT>(repo)

        sut.<행위>()

        assertFalse(sut.state.value.<필드>)
        assertTrue(repo.<발생 여부>())
    }

    // ── 예외 경로 ───────────────────────────────────────────

    @Spec("BR-<약어>-015")
    @Test
    fun `<BR 문장 그대로>`() = runTest {
        val repo = Fake<X>Repo()
        val sut = <SUT>(repo)

        sut.<행위>()
        repo.emitFailure(NetworkError)

        assertFalse(sut.state.value.finished)
        assertTrue(sut.state.value.retryAvailable)
    }

    // 타임아웃 등 시간 의존 검증은 가상 시간으로 제어한다.
    // 상수는 테스트에 박지 말고 프로덕션 상수를 참조한다.
    @Spec("BR-<약어>-016")
    @Test
    fun `<BR 문장 그대로>`() = runTest {
        val repo = Fake<X>Repo()
        val sut = <SUT>(repo)

        sut.<행위>()
        advanceTimeBy(<PROD_TIMEOUT_CONST> + 1.seconds)

        assertTrue(sut.state.value.<대체 경로 진입>)
    }
}


/**
 * Fake는 결과를 관측 가능하게 만드는 최소한의 실제 구현이다.
 * mock verify(호출 여부)가 아니라 상태를 검증하기 위해 사용한다.
 * UC 간 재사용되므로 새로 만들기 전에 기존 것을 찾을 것.
 */
class Fake<X>Repo(
    private val available: MutableSet<<Id>> = mutableSetOf(),
) : <X>Repository {

    private val started = mutableSetOf<<Id>>()

    // ── 프로덕션 인터페이스 구현 ──
    override fun has(id: <Id>) = id in available
    override fun request(id: <Id>) { started += id }

    // ── 검증용 질의 ──
    fun <발생 여부>(id: <Id>) = id in started

    // ── 시나리오 조작 ──
    fun emitFailure(e: Throwable) { /* ... */ }
    fun emitComplete(id: <Id>) { available += id }
}
