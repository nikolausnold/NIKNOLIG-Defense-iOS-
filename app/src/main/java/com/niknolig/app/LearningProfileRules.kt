package com.niknolig.app

internal object LearningProfileRules {
    const val MAX_SESSION_SUMMARY_LENGTH = 500

    fun incrementFeedbackCount(currentCount: Long, learningEnabled: Boolean): Long =
        when {
            !learningEnabled || currentCount == Long.MAX_VALUE -> currentCount
            else -> currentCount + 1
        }

    fun normalizeSessionSummary(summary: String): String? =
        summary.trim().take(MAX_SESSION_SUMMARY_LENGTH).ifEmpty { null }
}
