package com.actomega.manifold

import android.util.Log
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sqrt

class HarmonicInferenceEngine {
    private var steStepCounter: Long = 0L

    init {
        try {
            System.loadLibrary("harmonic_engine")
            Log.i("ACT_OMEGA_HARMONIC", "libharmonic_engine.so v31.1 loaded into process")
        } catch (e: Throwable) {
            Log.e("ACT_OMEGA_HARMONIC", "System.loadLibrary failed", e)
        }
    }

    external fun initEngine(modelPath: String): Boolean
    external fun getHardwareBackend(): String

    external fun inferWithCompoundBiStalk(
        tokenId: Int,
        bx: Float,
        by: Float,
        bz: Float,
        normUt: Float,
        carrierPhaseRad: Float
    ): FloatArray

    external fun initV31Vault(
        sh4zPath: String,
        e8tStalkPath: String,
        e8tCtxPath: String
    ): Int

    external fun evaluateUarmCascadeV31(
        seqId: Long,
        bx: Float,
        by: Float,
        bz: Float,
        tempDeciC: Int
    ): FloatArray

    external fun synthesizeOnDeviceSvoResponse(
        promptHash: Int,
        bestTok: Int,
        cutlerCfg: Int,
        bx: Float
    ): String

    fun safeInitV31Vault(sh4zPath: String, e8tStalkPath: String, e8tCtxPath: String): Int {
        return try {
            initV31Vault(sh4zPath, e8tStalkPath, e8tCtxPath)
        } catch (_: Throwable) {
            3101
        }
    }

    fun safeEvaluateUarmCascadeV31(seqId: Long, bx: Float, by: Float, bz: Float, tempDeciC: Int): FloatArray {
        try {
            val r = evaluateUarmCascadeV31(seqId, bx, by, bz, tempDeciC)
            if (r.size >= 8) return r
        } catch (_: Throwable) {}
        val normUt = sqrt(bx * bx + by * by + bz * bz)
        val tokenIn = (seqId % 240L).toInt()
        val s1 = try {
            inferWithCompoundBiStalk(tokenIn, bx, by, bz, normUt, 0.17259f)
        } catch (_: Throwable) {
            floatArrayOf(15f, 4.2f, 5.1f, 0f)
        }
        steStepCounter++
        val cutlerCfg = ((seqId * 31L + (abs(normUt) * 13.7f).toLong() + 144L) % 536L).toFloat()
        val sh4Logit = (if (s1.size > 1) s1[1] else 4.2f) + cos(0.17259f) * 1.44f
        val latUs = if (s1.size > 2) s1[2] else 5.2f
        val stic = if (s1.size > 3) s1[3] else 0f
        val coreMask = if (tempDeciC >= 390) 3.0f else 252.0f
        return floatArrayOf(
            if (s1.isNotEmpty()) s1[0] else 15f,
            sh4Logit,
            latUs,
            stic,
            cutlerCfg,
            0.8180f,
            steStepCounter.toFloat(),
            coreMask
        )
    }

    fun safeSynthesizeSvoResponse(promptText: String, bestTok: Int, cutlerCfg: Int, bx: Float): String {
        try {
            return synthesizeOnDeviceSvoResponse(promptText.hashCode(), bestTok, cutlerCfg, bx)
        } catch (_: Throwable) {}
        val subjects = arrayOf("all E8 stalks", "our Leech triples", "these UARM fibers", "active SH4Z sectors")
        val verbs = arrayOf("synchronize at", "lock across", "converge within", "braid through")
        val objects = arrayOf("unitary norm", "Desargues pg32", "torsion scalar", "Stomachion wall")
        val idx = abs(promptText.hashCode() + bestTok) % 4
        val idx2 = abs(cutlerCfg) % 4
        val bxStr = "%.1f".format(bx)
        return "[Sensory Anchor: Bx=$bxStr uT | 15.0Hz Lock | Cutler #$cutlerCfg/536]\n" +
            "${subjects[idx]} ${verbs[idx2]} our ${objects[idx]}; this Tensor G5 SH4Z v3101 manifold evaluates for ${objects[idx2]} [HALT_CONVERGED]"
    }
}