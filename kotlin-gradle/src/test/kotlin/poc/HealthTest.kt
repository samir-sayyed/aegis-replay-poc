package poc

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class HealthTest {
    @Test
    fun healthyStatusIsAccepted() {
        assertTrue(Health.isHealthy("ok"))
    }

    @Test
    fun otherStatusesAreRejected() {
        assertFalse(Health.isHealthy("degraded"))
    }
}
