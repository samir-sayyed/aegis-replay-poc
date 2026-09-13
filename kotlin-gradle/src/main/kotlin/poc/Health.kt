package poc

/** Small behaviour used by the cross-stack POC. */
object Health {
    fun isHealthy(status: String): Boolean = status == "ok"
}
