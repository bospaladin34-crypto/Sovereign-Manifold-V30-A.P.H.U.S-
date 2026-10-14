package com.actomega.manifold

import android.util.Log

class HarmonicInferenceEngine {
    init {
        try {
            System.loadLibrary("harmonic_engine")
            Log.i("ACT_OMEGA_HARMONIC", "libharmonic_engine.so successfully loaded into process")
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
}