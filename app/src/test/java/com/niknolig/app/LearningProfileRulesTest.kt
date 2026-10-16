package com.niknolig.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class LearningProfileRulesTest {
    @Test
    fun feedbackCountDoesNotChangeWithoutConsent() {
        assertEquals(3L, LearningProfileRules.incrementFeedbackCount(3, learningEnabled = false))
    }

    @Test
    fun feedbackCountIncrementsWithConsent() {
        assertEquals(4L, LearningProfileRules.incrementFeedbackCount(3, learningEnabled = true))
    }

    @Test
    fun feedbackCountDoesNotOverflow() {
        assertEquals(
            Long.MAX_VALUE,
            LearningProfileRules.incrementFeedbackCount(Long.MAX_VALUE, learningEnabled = true)
        )
    }

    @Test
    fun sessionSummaryIsTrimmed() {
        assertEquals("Next step", LearningProfileRules.normalizeSessionSummary("  Next step  "))
    }

    @Test
    fun emptySessionSummaryRemovesSavedValue() {
        assertNull(LearningProfileRules.normalizeSessionSummary(" \n\t "))
    }

    @Test
    fun sessionSummaryIsLimitedToFiveHundredCharacters() {
        val summary = "a".repeat(LearningProfileRules.MAX_SESSION_SUMMARY_LENGTH + 1)

        assertEquals(
            LearningProfileRules.MAX_SESSION_SUMMARY_LENGTH,
            LearningProfileRules.normalizeSessionSummary(summary)?.length
        )
    }
}
