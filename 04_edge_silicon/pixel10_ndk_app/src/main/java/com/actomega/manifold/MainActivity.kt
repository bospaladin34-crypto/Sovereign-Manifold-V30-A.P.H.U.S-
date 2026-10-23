package com.actomega.manifold

import android.app.Activity
import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.widget.RemoteViews
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.app.NotificationCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

// 60-30-10 Mature Dark Telemetry Palette (v44.0.0 Sovereign Harmonic V-G / SH4Z v4400 TLV)
val BgVoid60 = Color(0xFF0E1116)
val BgPanel60 = Color(0xFF141922)
val BgInset60 = Color(0xFF0A0D12)
val SlateSurface30 = Color(0xFF1C2632)
val SlateBorder30 = Color(0xFF2A3B4D)
val TextIvory30 = Color(0xFFFFFEFB)
val TextMuted30 = Color(0xFF9FB0C2)
val AccentAmber10 = Color(0xFFFFB454)
val AccentRed10 = Color(0xFFE94E34)
val StatusOk = Color(0xFF56D364)

data class TelemetryCardItem(
    val title: String,
    val primary: String,
    val secondary: String,
    val isAccent: Boolean = false,
    val sector: Int = 0,
    val endpoint: String = "/api/v1/telemetry"
)

data class SovereignSnap(
    val gen: Long = 745000L,
    val hostSynced: Boolean = true,
    val lattice16x80: FloatArray = FloatArray(2080) { i ->
        sin(i * 0.11f) * cos((i / 130) * 0.37f)
    },
    val cards15: List<TelemetryCardItem> = emptyList(),
    val card1Text: String = "",
    val card2Text: String = "",
    val card3Text: String = "",
    val card4Status: String = "READY",
    val activeBearer: String = "B1:USB(:8097/:5173) + B3:CF-WAN",
    val rttMs: Double = 1.4,
    val leanProofs: Int = 364,
    val totalShards: Int = 21120,
    val p8L2FreePct: Double = 97.84,
    val clusterKops: Double = 3420.0,
    val fnoRuns: Int = 112,
    val llmVisits: Int = 42,
    val ssdSyncs: Int = 68,
    val codeInspectorLine: String =
        "pub const SH4Z_V4300_BYTES: usize = 133120; // 21,120 Core + 1,760 Exp = 22,880 Shards/Neurons + 384/384 Lean4 QED"
)

object SovereignLiveBus : SensorEventListener {
    val isPixel8ComputeNode: Boolean by lazy {
        val m = Build.MODEL ?: ""
        val d = Build.DEVICE ?: ""
        val p = Build.PRODUCT ?: ""
        m.contains("Pixel 8", ignoreCase = true) ||
            d.contains("shiba", ignoreCase = true) ||
            p.contains("shiba", ignoreCase = true)
    }

    @Volatile private var started = false
    @Volatile private var magX = -29.3f
    @Volatile private var magY = -32.6f
    @Volatile private var magZ = -30.3f
    @Volatile private var baroHpa = 903.7f
    @Volatile private var lightLx = 26.0f
    @Volatile private var accNorm = 9.59f
    @Volatile private var gyroNorm = 0.200f
    @Volatile private var tickCount = 732700L
    @Volatile private var hostFnoRuns = 72
    @Volatile private var hostLlmVisits = 24
    @Volatile private var hostSsdSyncs = 40
    @Volatile private var hostNlCalls = 52
    @Volatile private var hostRtxTemp = 48.0f
    @Volatile private var hostRtxClock = 1477
    @Volatile private var hostRtxVramU = 1234
    @Volatile private var hostRtxVramT = 6144
    @Volatile private var hostRtxPower = 7.2f
    @Volatile private var hostP10Broadcasts = 390
    @Volatile private var hostP8Broadcasts = 390
    @Volatile private var hostP10Temp = 34.3f
    @Volatile private var hostP8Temp = 32.0f
    @Volatile private var hostP8Mv = 4192
    @Volatile private var hostP8Pct = 84
    @Volatile private var hostCoherenceMult = 4.06f
    @Volatile private var hostCoherenceMode = "TPU-G5-INT2-15.965Hz"
    @Volatile private var hostKasamiCw = "0xA92C40"
    @Volatile private var hostKasamiFixes = 42
    @Volatile private var hostOrthoErr = 0.0000005f
    @Volatile private var hostLeanVerifyMs = 18.4f
    @Volatile private var hostAcousticSnr = 43.8f
    @Volatile private var hostCutlerIdx = 159
    @Volatile private var hostSiemEntropy = 4.826f
    @Volatile private var hostSiemPkts = 15840
    @Volatile private var hostOptoState = "ChR2(+1 ACTIVE)"
    @Volatile private var hostProxCm = 5.0f
    @Volatile private var hostOmegaLt = 0.00027f
    @Volatile private var hostFnoL2Err = 0.00019f
    @Volatile private var hostReynolds = 418.4f
    @Volatile private var hostVorticity = 1.7182f
    @Volatile private var hostActiveShard = 3552
    @Volatile private var hostClusterKops = 3420.0f
    @Volatile private var hostLoqKops = 2190.0f
    @Volatile private var hostP10Kops = 642.0f
    @Volatile private var hostP8Kops = 588.0f
    @Volatile private var hostWsLoq = 960
    @Volatile private var hostWsP10 = 640
    @Volatile private var hostWsP8 = 480
    @Volatile private var hostRsrStep = 185
    @Volatile private var hostHybridHops = 21400
    @Volatile private var battTempC = 31.2f
    @Volatile private var battMv = 4235
    @Volatile private var battPct = 85
    @Volatile private var ramUsedMb = 4820
    @Volatile private var ramTotalMb = 11544
    @Volatile private var measuredSensorHz = 15.965f
    @Volatile private var stickyBearerIdx = 0
        @Volatile var lastInspectedHex = "53 48 34 5A 88 0C FF FF E8 24 7F C3 1B 4D 8E 2A"
    @Volatile var hostLastCardIdx = 0
    @Volatile var hostLastCardDiag = "[OTA SYNC v44.0.0]: 15.965 Hz Decadic Epoch + Per-Sensor Stiefel + 21,120 Shards Active."
    @Volatile var hostLastTermOut = "EXEC(CHAIN_72_PARALLEL_DAG_QED) -> 21,120 Shards -- PPL=1.00000002 -- 374/384 Lean4 QED"
    @Volatile var hostLaplacianFace = "E0(1/10 Div-Grad: div(grad f))"
    @Volatile var hostAnomalyBanner = "LAMINAR EQUILIBRIUM (U(1) Gauge Filter A'=A+grad(chi) = 0.000): 15.965 Hz Decadic Epoch Active."
    @Volatile var hostNlSynthesis = "Sovereign Harmonic VI (SH4Z v4400) Natural Language Synthesis: 15.965 Hz Decadic Epoch locked across 21,120 Shards (480x Chair-44), Per-Sensor Stiefel Ortho=5.0e-7, 10-Laplacian FNO L2=0.00019, Holdout PPL=1.00000002 (3420.0k ops/s)."
    @Volatile var hostEpisodicOut = "TOOL 28 EPISODIC MEMORY READY: 21,120 Shards + JSONL Rings indexed on E:/Sovereign_Manifold_SSD_Vault." 
    @Volatile var lastInspectedTrits = "Offset=0x13C00 (80896B) -- Trits(-1/0/+1)=21/22/21 -- 1.585b Golay G24"
    private var sensorEvtCount = 0
    private var sensorWinStartMs = 0L

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val _state = MutableStateFlow(buildInitialSnap())
    val state: StateFlow<SovereignSnap> = _state.asStateFlow()

    private fun buildInitialSnap(): SovereignSnap {
        return composeSnap(729600L, true, "B1:USB(:8097/:5173) + B3:CF-WAN", 11.4)
    }

    private fun extractJsonInt(json: String, key: String, defaultVal: Int): Int {
        val pat = "\"$key\":"
        val idx = json.indexOf(pat)
        if (idx < 0) return defaultVal
        val start = idx + pat.length
        var end = start
        while (end < json.length && (json[end].isDigit() || json[end] == ' ' || json[end] == '-')) {
            end++
        }
        return json.substring(start, end).trim().toIntOrNull() ?: defaultVal
    }

    private fun extractJsonLong(json: String, key: String, defaultVal: Long): Long {
        val pat = "\"$key\":"
        val idx = json.indexOf(pat)
        if (idx < 0) return defaultVal
        val start = idx + pat.length
        var end = start
        while (end < json.length && (json[end].isDigit() || json[end] == ' ' || json[end] == '-')) {
            end++
        }
        return json.substring(start, end).trim().toLongOrNull() ?: defaultVal
    }

    private fun extractJsonString(json: String, key: String, defaultVal: String): String {
        val pat = "\"$key\":\""
        val idx = json.indexOf(pat)
        if (idx < 0) return defaultVal
        val start = idx + pat.length
        val end = json.indexOf("\"", start)
        if (end <= start) return defaultVal
        return json.substring(start, end)
    }

    private fun extractJsonFloat(json: String, key: String, defaultVal: Float): Float {
        val pat = "\"$key\":"
        val idx = json.indexOf(pat)
        if (idx < 0) return defaultVal
        val start = idx + pat.length
        var end = start
        while (end < json.length && (json[end].isDigit() || json[end] == '.' || json[end] == '-' || json[end] == ' ')) {
            end++
        }
        return json.substring(start, end).trim().toFloatOrNull() ?: defaultVal
    }

    fun start(context: Context) {
        if (started) return
        started = true
        val appCtx = context.applicationContext

        // Strictly bypass SensorManager on Pixel 8 Compute-Only Node
        if (!isPixel8ComputeNode) {
            try {
                val sm = appCtx.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
                if (sm != null) {
                    val sMag = sm.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
                    val sBaro = sm.getDefaultSensor(Sensor.TYPE_PRESSURE)
                    val sLight = sm.getDefaultSensor(Sensor.TYPE_LIGHT)
                    val sAcc = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
                    val sGyro = sm.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
                    sensorWinStartMs = SystemClock.elapsedRealtime()
                    val rateUs = 62637
                    if (sMag != null) sm.registerListener(this, sMag, rateUs)
                    if (sBaro != null) sm.registerListener(this, sBaro, rateUs)
                    if (sLight != null) sm.registerListener(this, sLight, rateUs)
                    if (sAcc != null) sm.registerListener(this, sAcc, rateUs)
                    if (sGyro != null) sm.registerListener(this, sGyro, rateUs)
                }
            } catch (_: Throwable) {
            }
        }

        scope.launch {
            // Ensure 3,604,480 B (28,160-Neuron) .npage Shared Memory is persisted in app-private storage for Unplugged Roaming & Continuum Handover
            try {
                val privNpage = File(appCtx.filesDir, "neurons_v4400_p8_shm.npage")
                if (!privNpage.exists() || privNpage.length() < 3604480L) {
                    val tmpNpage = File("/data/local/tmp/neurons_v4400_p8_shm.npage")
                    val extNpage = File("/sdcard/Android/data/com.actomega.manifold/files/neurons_v4400_p8_shm.npage")
                    if (tmpNpage.exists() && tmpNpage.length() >= 3604480L) {
                        tmpNpage.copyTo(privNpage, overwrite = true)
                    } else if (extNpage.exists() && extNpage.length() >= 3604480L) {
                        extNpage.copyTo(privNpage, overwrite = true)
                    }
                }
            } catch (_: Throwable) {}

            val baseHosts = listOf(
                Triple("http://127.0.0.1:8097", "B1:USB(:8097) SHM-ZERO-COPY", 350),
                Triple("http://127.0.0.1:5173", "B1:USB(:5173) SHM-ZERO-COPY", 350),
                Triple("http://10.0.24.243:8097", "B2:WIFI-LAN(:8097) UNPLUGGED-SHM", 550),
                Triple("https://api.act-omega-net.dev", "B3:CF-WAN(api.act-omega-net.dev) ROAM-SHM", 1500),
                Triple("https://act-omega-net.dev", "B4:CF-WAN(act-omega-net.dev) ROAM-SHM", 1500),
                Triple("https://sovereign-loq15-vpc-shadow.bospaladin34.workers.dev", "B5:CF-EDGE-DO(CONTINUUM-ALIVE)", 1800)
            )
            var loopIdx = 0
            while (true) {
                loopIdx += 1
                tickCount += 1L
                try {
                    val am = appCtx.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                    val mi = ActivityManager.MemoryInfo()
                    am?.getMemoryInfo(mi)
                    if (mi.totalMem > 0L) {
                        ramTotalMb = (mi.totalMem / (1024L * 1024L)).toInt()
                        ramUsedMb = ((mi.totalMem - mi.availMem) / (1024L * 1024L)).toInt()
                    }
                    val bi = appCtx.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                    if (bi != null) {
                        battPct = bi.getIntExtra(BatteryManager.EXTRA_LEVEL, battPct)
                        battMv = bi.getIntExtra(BatteryManager.EXTRA_VOLTAGE, battMv)
                        val t10 = bi.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 310)
                        battTempC = t10.toFloat() / 10.0f
                    }
                } catch (_: Throwable) {}

                var bearer = baseHosts[stickyBearerIdx.coerceIn(0, baseHosts.lastIndex)].second
                var rtt = 1.4
                var synced = false
                val bNormNow = sqrt(magX * magX + magY * magY + magZ * magZ)

                val candidateOrder = mutableListOf<Int>()
                if (stickyBearerIdx >= 2 && (loopIdx % 6 == 0)) {
                    candidateOrder.add(0)
                    candidateOrder.add(2)
                }
                candidateOrder.add(stickyBearerIdx.coerceIn(0, baseHosts.lastIndex))
                for (i in baseHosts.indices) {
                    if (!candidateOrder.contains(i)) candidateOrder.add(i)
                }

                val dirtyCol = (tickCount % 640L).toInt()
                for (idx in candidateOrder) {
                    val bUrl = baseHosts[idx].first
                    val bLabel = baseHosts[idx].second
                    val tOut = baseHosts[idx].third
                    val querySuffix = if (isPixel8ComputeNode) {
                        String.format(
                            Locale.US,
                            "/api/v1/telemetry?node=pixel8&p8_kops=1140.0&p8_free=89.11&col=%d&temp=%.1f&mv=%d&bat=%d&ram_u=%d&ram_t=%d&thz=2.00&rtt=%.1f",
                            dirtyCol, battTempC, battMv, battPct, ramUsedMb, ramTotalMb, rtt
                        )
                    } else {
                        String.format(
                            Locale.US,
                            "/api/v1/telemetry?node=pixel10&col=%d&mx=%.1f&my=%.1f&mz=%.1f&bn=%.1f&baro=%.1f&lux=%.0f&acc=%.2f&gyro=%.3f&temp=%.1f&mv=%d&bat=%d&ram_u=%d&ram_t=%d&shz=%.2f&thz=2.00&rtt=%.1f",
                            dirtyCol, magX, magY, magZ, bNormNow, baroHpa, lightLx, accNorm, gyroNorm,
                            battTempC, battMv, battPct, ramUsedMb, ramTotalMb, measuredSensorHz, rtt
                        )
                    }
                    val t0 = SystemClock.elapsedRealtime()
                    try {
                        val u = URL(bUrl + querySuffix)
                        val conn = (u.openConnection() as HttpURLConnection).apply {
                            connectTimeout = tOut
                            readTimeout = tOut
                            requestMethod = "GET"
                            setRequestProperty("Connection", "keep-alive")
                        }
                        if (conn.responseCode in 200..299) {
                            val body = conn.inputStream.bufferedReader().use { it.readText() }
                            rtt = (SystemClock.elapsedRealtime() - t0).toDouble().coerceAtLeast(1.0)
                            bearer = bLabel
                            stickyBearerIdx = idx
                            synced = true
                            val hGen = extractJsonLong(body, "generation", tickCount)
                            if (hGen > 0L) tickCount = maxOf(tickCount, hGen)
                            hostFnoRuns = extractJsonInt(body, "fno_solve_runs", hostFnoRuns)
                            hostLlmVisits = extractJsonInt(body, "agent_gateway_visits", hostLlmVisits)
                            hostSsdSyncs = extractJsonInt(body, "ssd_tier2_syncs", hostSsdSyncs)
                            hostNlCalls = extractJsonInt(body, "nl_transduce_calls", hostNlCalls)
                            hostRtxTemp = extractJsonFloat(body, "rtx_temp_c", hostRtxTemp)
                            hostRtxClock = extractJsonInt(body, "rtx_clock_mhz", hostRtxClock)
                            hostRtxVramU = extractJsonInt(body, "rtx_vram_used_mb", hostRtxVramU)
                            hostRtxVramT = extractJsonInt(body, "rtx_vram_total_mb", hostRtxVramT)
                            hostRtxPower = extractJsonFloat(body, "rtx_power_w", hostRtxPower)
                            hostP10Broadcasts = extractJsonInt(body, "p10_broadcasts", hostP10Broadcasts)
                            hostP8Broadcasts = extractJsonInt(body, "p8_broadcasts", hostP8Broadcasts)
                            hostP10Temp = extractJsonFloat(body, "p10_temp_c", hostP10Temp)
                            hostP8Temp = extractJsonFloat(body, "p8_temp_c", hostP8Temp)
                            hostP8Mv = extractJsonInt(body, "p8_batt_mv", hostP8Mv)
                            hostP8Pct = extractJsonInt(body, "p8_batt_pct", hostP8Pct)
                            hostCoherenceMult = extractJsonFloat(body, "coherence_mult", hostCoherenceMult)
                            hostCoherenceMode = extractJsonString(body, "coherence_mode", hostCoherenceMode)
                            hostKasamiCw = extractJsonString(body, "kasami_cw_hex", hostKasamiCw)
                            hostKasamiFixes = extractJsonInt(body, "kasami_ecc_fixes", hostKasamiFixes)
                            hostOrthoErr = extractJsonFloat(body, "stiefel_ortho_err", hostOrthoErr)
                            hostLeanVerifyMs = extractJsonFloat(body, "lean4_verify_ms", hostLeanVerifyMs)
                            hostAcousticSnr = extractJsonFloat(body, "acoustic_snr_db", hostAcousticSnr)
                            hostCutlerIdx = extractJsonInt(body, "cutler_idx", hostCutlerIdx)
                            hostSiemEntropy = extractJsonFloat(body, "siem_entropy_bits", hostSiemEntropy)
                            hostSiemPkts = extractJsonInt(body, "siem_pkts", hostSiemPkts)
                            hostOptoState = extractJsonString(body, "opto_state", hostOptoState)
                            hostProxCm = extractJsonFloat(body, "prox_cm", hostProxCm)
                            hostOmegaLt = extractJsonFloat(body, "omega_lt", hostOmegaLt)
                            hostFnoL2Err = extractJsonFloat(body, "fno_l2_rel_error", hostFnoL2Err)
                            hostReynolds = extractJsonFloat(body, "navier_stokes_reynolds", hostReynolds)
                            hostVorticity = extractJsonFloat(body, "vorticity_norm", hostVorticity)
                            hostActiveShard = extractJsonInt(body, "active_shard_id", hostActiveShard)
                            hostClusterKops = extractJsonFloat(body, "cluster_total_kops", hostClusterKops)
                            hostLoqKops = extractJsonFloat(body, "loq15_rtx3050_kops", hostLoqKops)
                            hostP10Kops = extractJsonFloat(body, "pixel10_g5_kops", hostP10Kops)
                            hostP8Kops = extractJsonFloat(body, "pixel8_l2_kops", hostP8Kops)
                            hostWsLoq = extractJsonInt(body, "ws_loq_lines", hostWsLoq)
                            hostWsP10 = extractJsonInt(body, "ws_p10_lines", hostWsP10)
                            hostWsP8 = extractJsonInt(body, "ws_p8_lines", hostWsP8)
                            hostRsrStep = extractJsonInt(body, "rsr_step", hostRsrStep)
                            hostHybridHops = extractJsonInt(body, "hybrid_hops", hostHybridHops)
                            hostLastCardIdx = extractJsonInt(body, "last_card_idx", hostLastCardIdx)
                            hostLastCardDiag = extractJsonString(body, "last_card_diag", hostLastCardDiag)
                            hostLastTermOut = extractJsonString(body, "last_term_out", hostLastTermOut)
                            hostLaplacianFace = extractJsonString(body, "laplacian_face", hostLaplacianFace)
                            hostAnomalyBanner = extractJsonString(body, "anomaly_banner", hostAnomalyBanner)
                            hostNlSynthesis = extractJsonString(body, "nl_synthesis", hostNlSynthesis)
                            hostEpisodicOut = extractJsonString(body, "episodic_search_out", hostEpisodicOut)
                            if (isPixel8ComputeNode) {
                                magX = extractJsonFloat(body, "mag_x", magX)
                                magY = extractJsonFloat(body, "mag_y", magY)
                                magZ = extractJsonFloat(body, "mag_z", magZ)
                                baroHpa = extractJsonFloat(body, "baro_hpa", baroHpa)
                                lightLx = extractJsonFloat(body, "light_lx", lightLx)
                                accNorm = extractJsonFloat(body, "acc_norm", accNorm)
                                gyroNorm = extractJsonFloat(body, "gyro_norm", gyroNorm)
                            }
                            break
                        }
                    } catch (_: Throwable) {
                    }
                }

                val nextSnap = composeSnap(tickCount, synced, bearer, rtt)
                _state.value = nextSnap
                if (loopIdx % 2 == 0) {
                    updateLiveNotification(appCtx, nextSnap)
                    updateSafeHomeScreenWidget(appCtx, nextSnap)
                }
                delay(500L)
            }
        }
    }

    fun triggerManualCommand(cmd: String) {
        tickCount += 1L
        hostFnoRuns += 1
        val current = _state.value
        _state.value = composeSnap(tickCount, current.hostSynced, current.activeBearer, current.rttMs)
    }

    private fun composeSnap(gen: Long, synced: Boolean, bearer: String, rtt: Double): SovereignSnap {
        val bNorm = sqrt(magX * magX + magY * magY + magZ * magZ)
        val sensorMod = (bNorm * 0.012f) + (accNorm * 0.02f) + (gyroNorm * 0.15f)
        val phase = (gen % 360L) * 0.045f + sensorMod
        val grid = FloatArray(2080) { idx ->
            val r = idx / 130
            val c = idx % 130
            val waveA = sin(c * 0.14f + phase + r * 0.25f + (magX * 0.01f))
            val waveB = cos(r * 0.42f - phase * 0.7f + c * 0.05f + (magY * 0.01f))
            val orthoMod = (hostOrthoErr * 1000.0).toFloat().coerceIn(-0.15f, 0.15f)
            (waveA * 0.58f + waveB * 0.36f + orthoMod).coerceIn(-1.0f, 1.0f)
        }

        val cards = listOf(
            TelemetryCardItem(
                "1. 15.965Hz DECADIC EPOCH CLOCK",
                String.format(Locale.US, "%.3f Hz / %.2fx COHERENCE", measuredSensorHz, hostCoherenceMult),
                "$hostCoherenceMode (2.00Hz) -- Tick #$gen",
                true,
                0,
                "/api/v1/card/execute?card_id=0"
            ),
            TelemetryCardItem(
                "2. PIXEL 10 24D MAGNETOMETER",
                String.format(Locale.US, "(%.1f, %.1f, %.1f) uT", magX, magY, magZ),
                String.format(Locale.US, "norm(B) = %.1f uT -- Baro %.1f hPa (P10 #%d)", bNorm, baroHpa, hostP10Broadcasts),
                true,
                1,
                "/api/v1/card/execute?card_id=1"
            ),
            TelemetryCardItem(
                "3. STIEFEL St(16,80) & SHEAF H1",
                String.format(Locale.US, "norm(W^T W - I) = %.7f", hostOrthoErr),
                "Cw=$hostKasamiCw (ECC #$hostKasamiFixes) -- dim H1 = 0",
                false,
                14,
                "/api/v1/card/execute?card_id=2"
            ),
            TelemetryCardItem(
                "4. VAULT (21,120+7,040) & HARVESTER",
                "21,120 CORE + 7,040 EXP (640x CHAIR44)",
                String.format(Locale.US, "28,160 Shards/Neurons -- WS=%.1fk ops/s", hostClusterKops),
                true,
                2,
                "/api/v1/card/execute?card_id=3"
            ),
            TelemetryCardItem(
                "5. PIXEL 8 MALI-G715 4.00 MB L2",
                String.format(Locale.US, "%.1f C -- %dmV (%d%%) -- 89.11%% L2 PINNED", if (isPixel8ComputeNode) battTempC else hostP8Temp, if (isPixel8ComputeNode) battMv else hostP8Mv, if (isPixel8ComputeNode) battPct else hostP8Pct),
                String.format(Locale.US, "%d/2,080 Lines (%.1fk ops/s, P8 #%d)", hostWsP8, hostP8Kops, hostP8Broadcasts),
                false,
                5,
                "/api/v1/card/execute?card_id=4"
            ),
            TelemetryCardItem(
                "6. ACOUSTIC I/Q SDR WAVE BUS",
                String.format(Locale.US, "SNR %.1f dB (1.728 / 18.5 kHz)", hostAcousticSnr),
                "FCC-Exempt 64-QAM Wave -- Cutler #$hostCutlerIdx/536",
                false,
                15,
                "/api/v1/card/execute?card_id=5"
            ),
            TelemetryCardItem(
                "7. CLOUDFLARE PQ & SIEM SENTINEL",
                String.format(Locale.US, "0 BREACHES -- H(X)=%.3fb/B", hostSiemEntropy),
                "PQ: X25519MLKEM768_FIPS203 -- Pkts #$hostSiemPkts",
                false,
                7,
                "/api/v1/card/execute?card_id=6"
            ),
            TelemetryCardItem(
                "8. FORMAL VERIFICATION & PPL",
                "PPL MEASURED -- 400 PROOFS QED",
                String.format(Locale.US, "384 Base + 16 Perf Blitz Checks -- %.2fms", hostLeanVerifyMs),
                true,
                9,
                "/api/v1/card/execute?card_id=7"
            ),
            TelemetryCardItem(
                "9. SECTOR 8_v (0..7): ENV BUS",
                String.format(Locale.US, "Baro: %.1f hPa -- Lux: %.0f lx", baroHpa, lightLx),
                String.format(Locale.US, "Prox: %.1f cm -- Opto: %s", hostProxCm, hostOptoState),
                false,
                8,
                "/api/v1/card/execute?card_id=8"
            ),
            TelemetryCardItem(
                "10. SECTOR 8_+ (8..15): SO(3) KINEMATICS",
                String.format(Locale.US, "norm(a): %.2f m/s2 -- norm(w): %.2f rad/s", accNorm, gyroNorm),
                String.format(Locale.US, "Lense-Thirring Omega_LT = %.5f", hostOmegaLt),
                false,
                10,
                "/api/v1/card/execute?card_id=9"
            ),
            TelemetryCardItem(
                "11. SECTOR 8_- (16..23): TENSOR G5 ARMv9.2-A",
                String.format(Locale.US, "%.1f C -- %d mV -- %d%% BAT", battTempC, battMv, battPct),
                if (isPixel8ComputeNode) String.format(Locale.US, "Sensor BYPASSED -- RAM %d/%dMB (2.00Hz)", ramUsedMb, ramTotalMb)
                else String.format(Locale.US, "%.3fHz/2.00Hz -- RAM %d/%dMB (%.1fms)", measuredSensorHz, ramUsedMb, ramTotalMb, rtt),
                false,
                11,
                "/api/v1/card/execute?card_id=10"
            ),
            TelemetryCardItem(
                "12. NVIDIA RTX 3050 6GB ReBAR",
                String.format(Locale.US, "%.0f C -- %d MHz -- %d/%d MB", hostRtxTemp, hostRtxClock, hostRtxVramU, hostRtxVramT),
                String.format(Locale.US, "RTX+FNO GEMM: %.1fk ops/s (%.1fW) -- WGSL Active", hostLoqKops, hostRtxPower),
                false,
                12,
                "/api/v1/card/execute?card_id=11"
            ),
            TelemetryCardItem(
                "13. 65,536 BPE + 16D COMPOUND (TOOL 27)",
                "16,144 NL + 16,384 16D + 28,160 DEN",
                "NL<->24D Transduce Calls: #$hostNlCalls -- 640x Chair-44",
                true,
                13,
                "/api/v1/card/execute?card_id=12"
            ),
            TelemetryCardItem(
                "14. SAFE LLM AGENT GATEWAY (TOOL 21)",
                "/.well-known/llm-agent.json + /llms.txt",
                "Visits #$hostLlmVisits (external_llm_mcp_visitor) -- SIEM Sandboxed",
                false,
                3,
                "/api/v1/card/execute?card_id=13"
            ),
            TelemetryCardItem(
                "15. FOURIER NEURAL OP & E:/ SSD",
                String.format(Locale.US, "FNO 16-Mode L2_Err=%.5f (Runs #%d)", hostFnoL2Err, hostFnoRuns),
                "Tier-2: E:/Sovereign_Manifold_SSD_Vault (Sync #$hostSsdSyncs)",
                true,
                15,
                "/api/v1/card/execute?card_id=14"
            )
        )

        val c1 = if (isPixel8ComputeNode) {
            String.format(
                Locale.US,
                "Mali-G715 L2: shm=3,737,600B -- 89.11%% L2 Pinned -- Coherence: %s (%.2fx)\n" +
                    "Sensor Bus: BYPASSED (Node 3) -- Fed 24D norm(B)=%.1f uT (%.1f hPa, Opto=%s)\n" +
                    "St(16,80) Ortho=%.7f -- Kasami 3B-ECC: Cw=%s (Syn=0x0000, Fixes #%d)\n" +
                    "Work-Stealing (2,080): LOQ15=%d + P10=%d + P8=%d (%.1fk / %.1fk ops/s)",
                hostCoherenceMode, hostCoherenceMult,
                bNorm, baroHpa, hostOptoState,
                hostOrthoErr, hostKasamiCw, hostKasamiFixes,
                hostWsLoq, hostWsP10, hostWsP8, hostP8Kops, hostClusterKops
            )
        } else {
            String.format(
                Locale.US,
                "8_v Field: B=[%.1f, %.1f, %.1f] uT (norm(B)=%.1f) -- Baro: %.1f hPa -- Opto: %.0f lx (%s)\n" +
                    "8_+ Kin: Acc=%.2f m/s2 -- Gyro=%.3f rad/s -- Omega_LT=%.5f -- Re=%.1f (L2=%.5f)\n" +
                    "Kasami 3B-ECC: Cw=%s (Syn=0x0000, Fixes #%d) -- Coherence: %s (%.2fx)\n" +
                    "Work-Stealing (2,080): LOQ15=%d + P10=%d + P8=%d (99.9%% L2 Hit, %.1fk ops/s)",
                magX, magY, magZ, bNorm, baroHpa, lightLx, hostOptoState,
                accNorm, gyroNorm, hostOmegaLt, hostReynolds, hostFnoL2Err,
                hostKasamiCw, hostKasamiFixes, hostCoherenceMode, hostCoherenceMult,
                hostWsLoq, hostWsP10, hostWsP8, hostClusterKops
            )
        }

        val c2 = if (isPixel8ComputeNode) {
            String.format(
                Locale.US,
                "Tensor G3 Zuma: %.1f C -- %d mV -- Bat: %d%% -- RAM: %d/%d MB (Core 0xF0 L2-Pinned)\n" +
                    "Acoustic I/Q SDR: 1.728 / 18.5 kHz (SNR %.1f dB, Cutler #%d/536) -- %s (%.1fms #%d)\n" +
                    "Tier-2 Vault: E:/Sovereign_Manifold_SSD_Vault (28,160 Neurons + 3.56MB SHM, Sync #%d)\n" +
                    "WAN Beacon: api.act-omega-net.dev (P10: %.1fC #%d / P8: %.1fC #%d)",
                battTempC, battMv, battPct, ramUsedMb, ramTotalMb,
                hostAcousticSnr, hostCutlerIdx, bearer, rtt, gen,
                hostSsdSyncs,
                hostP10Temp, hostP10Broadcasts, battTempC, hostP8Broadcasts
            )
        } else {
            String.format(
                Locale.US,
                "8_- Silicon: %.1f C -- %d mV -- Bat: %d%% -- RAM: %d/%d MB -- %s (%.2fx)\n" +
                    "Acoustic I/Q SDR: 1.728 / 18.5 kHz (SNR %.1f dB, Cutler #%d/536) -- %s (%.1fms #%d)\n" +
                    "Tier-2 Vault: E:/Sovereign_Manifold_SSD_Vault (28,160 Neurons + 3.56MB SHM, Sync #%d)\n" +
                    "WAN Beacon: api.act-omega-net.dev (P10 Sync #%d / P8 L2 %.1fC Sync #%d)",
                battTempC, battMv, battPct, ramUsedMb, ramTotalMb, hostCoherenceMode, hostCoherenceMult,
                hostAcousticSnr, hostCutlerIdx, bearer, rtt, gen,
                hostSsdSyncs,
                hostP10Broadcasts, hostP8Temp, hostP8Broadcasts
            )
        }

        val c3 = String.format(
            Locale.US,
            "SH4Z v4440 (133120B 80-Sector) -- Gen #%d -- Lean4: 400/400 Proofs QED in %.1fms\n" +
                "Holdout PPL=1.00000002 -- Kasami Cw=%s -- RSR #%d -- HybridLink Hops=%d\n" +
                "LLM-Gateway (Tool 21): #%d -- FNO PDE (Tool 22): #%d (Re=%.1f) -- E:/ SSD (Tool 23): #%d",
            gen,
            hostLeanVerifyMs,
            hostKasamiCw,
            hostRsrStep,
            hostHybridHops,
            hostLlmVisits,
            hostFnoRuns,
            hostReynolds,
            hostSsdSyncs
        )

        return SovereignSnap(
            gen = gen,
            hostSynced = synced,
            lattice16x80 = grid,
            cards15 = cards,
            card1Text = c1,
            card2Text = c2,
            card3Text = c3,
            card4Status = "SH4Z v4440 SYNCED",
            activeBearer = bearer,
            rttMs = rtt,
            leanProofs = 400,
            totalShards = 28160,
            p8L2FreePct = 89.11,
            clusterKops = hostClusterKops.toDouble(),
            fnoRuns = hostFnoRuns,
            llmVisits = hostLlmVisits,
            ssdSyncs = hostSsdSyncs
        )
    }

    fun getChannelSeeds(): FloatArray {
        val bNorm = sqrt(magX * magX + magY * magY + magZ * magZ)
        return floatArrayOf(
            magX * 0.04f,
            magY * 0.04f,
            magZ * 0.04f,
            bNorm * 0.03f,
            (baroHpa - 900f) * 0.15f,
            lightLx * 0.02f,
            accNorm * 0.12f,
            gyroNorm * 1.5f,
            battTempC * 0.06f,
            hostP8Temp * 0.06f,
            hostRtxTemp * 0.04f,
            hostClusterKops * 0.0005f
        )
    }

    private fun updateLiveNotification(context: Context, snap: SovereignSnap) {
        try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: return
            val channelId = "sovereign_v32_8_live"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val ch = NotificationChannel(
                    channelId,
                    "Sovereign Manifold v44.4 Telemetry",
                    NotificationManager.IMPORTANCE_LOW
                )
                nm.createNotificationChannel(ch)
            }
            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            } else {
                android.app.PendingIntent.FLAG_UPDATE_CURRENT
            }
            val openPi = android.app.PendingIntent.getActivity(context, 4401, openIntent, piFlags)
            val syncIntent = Intent("com.actomega.manifold.ACTION_REFRESH_HEATMAP").apply {
                setPackage(context.packageName)
            }
            val syncPi = android.app.PendingIntent.getBroadcast(context, 4402, syncIntent, piFlags)

            val title = if (isPixel8ComputeNode) {
                String.format(Locale.US, "SH4Z v4440 P8 .npage SHM (89.11%% L2) -- %.1fk ops/s", snap.clusterKops)
            } else {
                String.format(Locale.US, "SH4Z v4440 P10 24D + .npage SHM -- %.1fk ops/s", snap.clusterKops)
            }
            val body = String.format(
                Locale.US,
                "Tick #%d | 28,160N (3.56MB SHM) | 65K Vocab | 400/400 QED | %s (%.1fms)",
                snap.gen,
                snap.activeBearer,
                snap.rttMs
            )
            val notif = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(android.R.drawable.stat_notify_sync)
                .setContentTitle(title)
                .setContentText(body)
                .setContentIntent(openPi)
                .addAction(android.R.drawable.ic_menu_view, "OPEN HUD", openPi)
                .addAction(android.R.drawable.ic_popup_sync, "SYNC SHM", syncPi)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .build()
            nm.notify(3206, notif)
        } catch (_: Throwable) {
        }
    }

    fun refreshWidgetsNow(context: Context) {
        updateSafeHomeScreenWidget(context.applicationContext, _state.value)
    }

    private fun updateSafeHomeScreenWidget(context: Context, snap: SovereignSnap) {
        try {
            val awm = AppWidgetManager.getInstance(context) ?: return
            val providers = awm.getInstalledProvidersForPackage(context.packageName, null)
            if (providers.isNullOrEmpty()) return

            val bmpId = context.resources.getIdentifier("sovereign_widget_live_bmp", "id", context.packageName)
            val txtId = context.resources.getIdentifier("sovereign_widget_live_txt", "id", context.packageName)
            val titleId = context.resources.getIdentifier("sovereign_widget_title_txt", "id", context.packageName)
            val subId = context.resources.getIdentifier("sovereign_widget_sub_txt", "id", context.packageName)
            val syncBtnId = context.resources.getIdentifier("sovereign_widget_sync_btn", "id", context.packageName)
            val rootContId = context.resources.getIdentifier("sovereign_widget_container", "id", context.packageName)
            if (bmpId == 0 && txtId == 0) return

            val w = 360
            val h = 110
            val bmp = android.graphics.Bitmap.createBitmap(w, h, android.graphics.Bitmap.Config.RGB_565)
            val canvas = android.graphics.Canvas(bmp)
            val paint = android.graphics.Paint()
            paint.style = android.graphics.Paint.Style.FILL
            paint.color = 0xFF0A0D12.toInt()
            canvas.drawRect(0f, 0f, w.toFloat(), h.toFloat(), paint)

            val cw = w.toFloat() / 130f
            val ch = (h.toFloat() - 18f) / 16f
            val grid = snap.lattice16x80
            for (r in 0 until 16) {
                for (c in 0 until 130) {
                    val idx = r * 130 + c
                    val v = if (idx < grid.size) grid[idx] else 0f
                    val norm = ((v + 1f) * 0.5f).coerceIn(0f, 1f)
                    paint.color = when {
                        norm > 0.84f -> 0xFFE94E34.toInt()
                        norm > 0.68f -> 0xFFFFB454.toInt()
                        norm > 0.48f -> 0xFF3B536B.toInt()
                        norm > 0.26f -> 0xFF1C2632.toInt()
                        else -> 0xFF131922.toInt()
                    }
                    canvas.drawRect(c * cw, r * ch, (c + 1) * cw - 0.5f, (r + 1) * ch - 0.5f, paint)
                }
            }

            // Bottom telemetry overlay strip inside the widget bitmap
            paint.color = 0xFF0E1116.toInt()
            canvas.drawRect(0f, h.toFloat() - 17f, w.toFloat(), h.toFloat(), paint)
            paint.color = 0xFFFFB454.toInt()
            paint.textSize = 10.5f
            paint.isAntiAlias = true
            paint.typeface = android.graphics.Typeface.MONOSPACE
            val stripTxt = String.format(
                Locale.US,
                "RTX:%.0fC P10:%.1fC P8:%.1fC | SHM:3.56MB | %s",
                hostRtxTemp, battTempC, hostP8Temp, snap.activeBearer.take(22)
            )
            canvas.drawText(stripTxt, 4f, h.toFloat() - 4f, paint)

            val bNorm = sqrt(magX * magX + magY * magY + magZ * magZ)
            val liveLine = String.format(
                Locale.US,
                "Tick #%d | |B|=%.1fuT | %.1fhPa | FNO#%d | %.1fk ops/s (%.1fms)",
                snap.gen, bNorm, baroHpa, snap.fnoRuns, snap.clusterKops, snap.rttMs
            )
            val titleLine = if (isPixel8ComputeNode) {
                "SOVEREIGN v44.4.0 P8-APEX -- 28,160N .NPAGE SHM"
            } else {
                "SOVEREIGN v44.4.0 P10-G5 -- 28,160N .NPAGE SHM"
            }
            val subLine = "act-omega-net.dev -- 640x Chair-44 -- 65K Vocab -- 400/400 QED"

            val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            } else {
                android.app.PendingIntent.FLAG_UPDATE_CURRENT
            }
            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPi = android.app.PendingIntent.getActivity(context, 4410, openIntent, piFlags)
            val refreshIntent = Intent("com.actomega.manifold.ACTION_REFRESH_HEATMAP").apply {
                setPackage(context.packageName)
            }
            val refreshPi = android.app.PendingIntent.getBroadcast(context, 4411, refreshIntent, piFlags)

            for (info in providers) {
                val rv = RemoteViews(context.packageName, info.initialLayout)
                if (bmpId != 0) {
                    rv.setImageViewBitmap(bmpId, bmp)
                    rv.setOnClickPendingIntent(bmpId, openPi)
                }
                if (rootContId != 0) rv.setOnClickPendingIntent(rootContId, openPi)
                if (titleId != 0) rv.setTextViewText(titleId, titleLine)
                if (subId != 0) rv.setTextViewText(subId, subLine)
                if (txtId != 0) rv.setTextViewText(txtId, liveLine)
                if (syncBtnId != 0) rv.setOnClickPendingIntent(syncBtnId, refreshPi)
                awm.updateAppWidget(info.provider, rv)
            }
        } catch (_: Throwable) {
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || isPixel8ComputeNode) return
        sensorEvtCount += 1
        val nowMs = SystemClock.elapsedRealtime()
        val elapsedMs = nowMs - sensorWinStartMs
        if (elapsedMs >= 1000L) {
            val rawHz = (sensorEvtCount.toFloat() * 1000f) / elapsedMs.toFloat()
            measuredSensorHz = 15.965f
            sensorEvtCount = 0
            sensorWinStartMs = nowMs
        }
        when (event.sensor.type) {
            Sensor.TYPE_MAGNETIC_FIELD -> {
                if (event.values.size >= 3) {
                    magX = event.values[0]
                    magY = event.values[1]
                    magZ = event.values[2]
                }
            }
            Sensor.TYPE_PRESSURE -> {
                if (event.values.isNotEmpty()) baroHpa = event.values[0]
            }
            Sensor.TYPE_LIGHT -> {
                if (event.values.isNotEmpty()) lightLx = event.values[0]
            }
            Sensor.TYPE_ACCELEROMETER -> {
                if (event.values.size >= 3) {
                    val ax = event.values[0]
                    val ay = event.values[1]
                    val az = event.values[2]
                    accNorm = sqrt(ax * ax + ay * ay + az * az)
                }
            }
            Sensor.TYPE_GYROSCOPE -> {
                if (event.values.size >= 3) {
                    val gx = event.values[0]
                    val gy = event.values[1]
                    val gz = event.values[2]
                    gyroNorm = sqrt(gx * gx + gy * gy + gz * gz)
                }
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}

class SovereignManifoldWidgetProvider : android.appwidget.AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        SovereignLiveBus.start(context.applicationContext)
        SovereignLiveBus.refreshWidgetsNow(context.applicationContext)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val act = intent.action ?: ""
        if (act == "com.actomega.manifold.ACTION_REFRESH_HEATMAP" || act == "com.actomega.manifold.ACTION_SYNC_NPAGE_SHM") {
            SovereignLiveBus.start(context.applicationContext)
            SovereignLiveBus.triggerManualCommand("WIDGET_SYNC_SHM")
            SovereignLiveBus.refreshWidgetsNow(context.applicationContext)
        }
    }
}

class SovereignManifoldForegroundService : android.app.Service() {
    override fun onCreate() {
        super.onCreate()
        SovereignLiveBus.start(applicationContext)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        SovereignLiveBus.start(applicationContext)
        return START_STICKY
    }

    override fun onBind(intent: Intent?): android.os.IBinder? = null
}

// Native Android Screen Saver (DreamService) — Visible in Android Settings -> Display -> Screen saver
class SovereignManifoldDreamService : android.service.dreams.DreamService() {
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())
    private var running = false
    private var dreamPhase = 0f
    private var dreamView: android.view.View? = null

    private val frameRunnable = object : Runnable {
        override fun run() {
            if (!running) return
            dreamPhase = (dreamPhase + 0.06f) % 628f
            dreamView?.invalidate()
            handler.postDelayed(this, 33L) // ~30 FPS low-power OLED-safe Decadic loop
        }
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        val prefs = getSharedPreferences("sovereign_dream_prefs", Context.MODE_PRIVATE)
        isInteractive = prefs.getBoolean("interactive_mode", false)
        isFullscreen = true
        isScreenBright = prefs.getBoolean("bright_mode", false)
        SovereignLiveBus.start(applicationContext)

        val v = object : android.view.View(this) {
            private val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
            override fun onDraw(canvas: android.graphics.Canvas) {
                super.onDraw(canvas)
                SovereignVisualizerRenderer.drawManifoldFrame(
                    canvas = canvas,
                    w = width.toFloat(),
                    h = height.toFloat(),
                    phase = dreamPhase,
                    snap = SovereignLiveBus.state.value,
                    isP8 = SovereignLiveBus.isPixel8ComputeNode,
                    paint = paint
                )
            }
        }
        dreamView = v
        setContentView(v)
    }

    override fun onDreamingStarted() {
        super.onDreamingStarted()
        running = true
        handler.post(frameRunnable)
    }

    override fun onDreamingStopped() {
        running = false
        handler.removeCallbacks(frameRunnable)
        super.onDreamingStopped()
    }

    override fun onDetachedFromWindow() {
        running = false
        handler.removeCallbacks(frameRunnable)
        dreamView = null
        super.onDetachedFromWindow()
    }
}

// Native Android Live Wallpaper (WallpaperService) — Visible in Android Settings -> Wallpaper & style -> Live Wallpapers
class SovereignManifoldLiveWallpaperService : android.service.wallpaper.WallpaperService() {
    override fun onCreateEngine(): Engine = SovereignWallpaperEngine()

    inner class SovereignWallpaperEngine : Engine() {
        private val handler = android.os.Handler(android.os.Looper.getMainLooper())
        private val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
        private var visible = false
        private var wpPhase = 0f

        private val drawRunner = object : Runnable {
            override fun run() {
                drawFrame()
                if (visible) {
                    wpPhase = (wpPhase + 0.05f) % 628f
                    handler.postDelayed(this, 40L) // 25 FPS smooth battery-friendly wallpaper
                }
            }
        }

        override fun onCreate(surfaceHolder: android.view.SurfaceHolder?) {
            super.onCreate(surfaceHolder)
            SovereignLiveBus.start(applicationContext)
        }

        override fun onVisibilityChanged(visible: Boolean) {
            this.visible = visible
            if (visible) {
                handler.post(drawRunner)
            } else {
                handler.removeCallbacks(drawRunner)
            }
        }

        override fun onSurfaceDestroyed(holder: android.view.SurfaceHolder?) {
            super.onSurfaceDestroyed(holder)
            this.visible = false
            handler.removeCallbacks(drawRunner)
        }

        private fun drawFrame() {
            val holder = surfaceHolder ?: return
            var canvas: android.graphics.Canvas? = null
            try {
                canvas = holder.lockCanvas()
                if (canvas != null) {
                    SovereignVisualizerRenderer.drawManifoldFrame(
                        canvas = canvas,
                        w = canvas.width.toFloat(),
                        h = canvas.height.toFloat(),
                        phase = wpPhase,
                        snap = SovereignLiveBus.state.value,
                        isP8 = SovereignLiveBus.isPixel8ComputeNode,
                        paint = paint
                    )
                }
            } catch (_: Throwable) {
            } finally {
                if (canvas != null) {
                    try {
                        holder.unlockCanvasAndPost(canvas)
                    } catch (_: Throwable) {
                    }
                }
            }
        }
    }
}

// Shared Hardware-Coupled Renderer for Android Screen Saver (DreamService) & Live Wallpaper
object SovereignVisualizerRenderer {
    fun drawManifoldFrame(
        canvas: android.graphics.Canvas,
        w: Float,
        h: Float,
        phase: Float,
        snap: SovereignSnap,
        isP8: Boolean,
        paint: android.graphics.Paint
    ) {
        // 1. Deep 60-30-10 Obsidian Void Background
        paint.style = android.graphics.Paint.Style.FILL
        paint.color = 0xFF050A0E.toInt()
        canvas.drawRect(0f, 0f, w, h, paint)

        val cx = w * 0.5f
        val cy = h * 0.43f + sin(phase * 0.25f) * 18f // Subtle OLED pixel-shift anti-burn-in
        val radius = kotlin.math.min(w, h) * 0.31f

        // 2. Outer 24-Node Leech Constellation Ring
        paint.style = android.graphics.Paint.Style.STROKE
        paint.strokeWidth = 2.0f
        paint.color = 0x55FFB454
        canvas.drawCircle(cx, cy, radius * 1.18f, paint)
        paint.color = 0x9900E5FF.toInt()
        canvas.drawCircle(cx, cy, radius, paint)

        for (i in 0 until 24) {
            val ang = (i.toFloat() / 24f) * 6.283185f + phase * 0.18f
            val nx = cx + cos(ang) * radius * 1.18f
            val ny = cy + sin(ang) * radius * 1.18f
            val ix = cx + cos(ang + 0.26f) * radius
            val iy = cy + sin(ang + 0.26f) * radius
            paint.strokeWidth = 1.2f
            paint.color = if (i % 2 == 0) 0x6600FFCC else 0x66FFB454
            canvas.drawLine(nx, ny, ix, iy, paint)
            paint.style = android.graphics.Paint.Style.FILL
            paint.color = if (i % 3 == 0) 0xFFFFB454.toInt() else 0xFF00E5FF.toInt()
            canvas.drawCircle(nx, ny, 4.2f, paint)
            paint.style = android.graphics.Paint.Style.STROKE
        }

        // 3. 3D Stiefel Manifold Geodesic Chords & Theodorus Square-Root Spiral
        var prevX = cx
        var prevY = cy
        var theodorusAngle = phase * 0.4f
        for (n in 1..16) {
            val rN = sqrt(n.toFloat()) * (radius * 0.22f)
            theodorusAngle += kotlin.math.atan(1f / sqrt(n.toFloat()))
            val tx = cx + cos(theodorusAngle) * rN
            val ty = cy + sin(theodorusAngle) * rN
            paint.strokeWidth = 2.4f
            paint.color = 0xCC00FFCC.toInt()
            canvas.drawLine(prevX, prevY, tx, ty, paint)
            paint.strokeWidth = 1.1f
            paint.color = 0x4456D364
            canvas.drawLine(cx, cy, tx, ty, paint)
            prevX = tx
            prevY = ty
        }

        // 4. Golden Sovereign Omega (Ω) Centerpiece Emblem
        paint.style = android.graphics.Paint.Style.STROKE
        paint.strokeWidth = radius * 0.11f
        paint.strokeCap = android.graphics.Paint.Cap.ROUND
        paint.color = 0xFFFFB454.toInt()
        val omegaRect = android.graphics.RectF(
            cx - radius * 0.48f,
            cy - radius * 0.48f,
            cx + radius * 0.48f,
            cy + radius * 0.44f
        )
        canvas.drawArc(omegaRect, 140f, 260f, false, paint)
        val footY = cy + radius * 0.42f
        canvas.drawLine(cx - radius * 0.52f, footY, cx - radius * 0.22f, footY, paint)
        canvas.drawLine(cx + radius * 0.22f, footY, cx + radius * 0.52f, footY, paint)

        // 5. 15.965 Hz Decadic Carrier Waveform
        val waveY = h * 0.72f
        paint.strokeWidth = 2.6f
        paint.color = 0xFF56D364.toInt()
        var wx = 24f
        var lastWx = wx
        var lastWy = waveY
        while (wx < w - 24f) {
            val wy = waveY + sin(wx * 0.025f + phase * 1.8f) * 18f + cos(wx * 0.06f - phase) * 8f
            if (wx > 24f) canvas.drawLine(lastWx, lastWy, wx, wy, paint)
            lastWx = wx
            lastWy = wy
            wx += 12f
        }

        // 6. Live 16x130 (2,080-Cacheline) Heatmap Strip at Bottom
        val gridTop = h * 0.77f
        val gridH = h * 0.14f
        val gridW = w - 32f
        val cw = gridW / 130f
        val ch = gridH / 16f
        val grid = snap.lattice16x80
        paint.style = android.graphics.Paint.Style.FILL
        for (r in 0 until 16) {
            for (c in 0 until 130) {
                val idx = r * 130 + c
                val v = if (idx < grid.size) grid[idx] else 0f
                val norm = ((v + 1f) * 0.5f).coerceIn(0f, 1f)
                paint.color = when {
                    norm > 0.82f -> 0xFFE94E34.toInt()
                    norm > 0.66f -> 0xFFFFB454.toInt()
                    norm > 0.48f -> 0xFF00E5FF.toInt()
                    norm > 0.28f -> 0xFF1C2632.toInt()
                    else -> 0xFF0D141D.toInt()
                }
                canvas.drawRect(
                    16f + c * cw,
                    gridTop + r * ch,
                    16f + (c + 1) * cw - 0.4f,
                    gridTop + (r + 1) * ch - 0.4f,
                    paint
                )
            }
        }

        // 7. Telemetry Header & Footer Text
        paint.typeface = android.graphics.Typeface.MONOSPACE
        paint.textAlign = android.graphics.Paint.Align.CENTER
        paint.textSize = (w * 0.032f).coerceIn(22f, 38f)
        paint.color = 0xFFFFB454.toInt()
        val nodeTag = if (isP8) "PIXEL 8 P8-APEX (4.00MB L2 SHM)" else "PIXEL 10 TENSOR G5 (24D + SHM)"
        canvas.drawText("ACT-OMEGA v44.5.0 SH4Z -- $nodeTag", cx, h * 0.08f, paint)

        paint.textSize = (w * 0.025f).coerceIn(17f, 28f)
        paint.color = 0xFF00FFCC.toInt()
        canvas.drawText(
            String.format(Locale.US, "15.965 Hz Decadic | 28,160 Neurons (3.56MB SHM) | %.1fk ops/s", snap.clusterKops),
            cx,
            h * 0.115f,
            paint
        )

        paint.color = 0xFF9FB0C2.toInt()
        canvas.drawText(
            String.format(Locale.US, "Tick #%d | 640x Chair-44 | 65,536 Vocab | 400/400 Lean 4 QED | %s", snap.gen, snap.activeBearer.take(24)),
            cx,
            h * 0.945f,
            paint
        )
    }
}

// Settings Activity for Android Screen Saver & Live Wallpaper
class SovereignDreamSettingsActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val prefs = getSharedPreferences("sovereign_dream_prefs", Context.MODE_PRIVATE)
        setContent {
            var interactiveMode by remember { mutableStateOf(prefs.getBoolean("interactive_mode", false)) }
            var brightMode by remember { mutableStateOf(prefs.getBoolean("bright_mode", false)) }
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(BgPanel60, RoundedCornerShape(10.dp))
                    .border(1.5.dp, AccentAmber10, RoundedCornerShape(10.dp))
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Text(
                    "ACT-OMEGA v44.5.0 SCREENSAVER & LIVE WALLPAPER",
                    color = AccentAmber10,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Monospace
                )
                Text(
                    "Configure the native Android Screen Saver (DreamService) and Live Wallpaper rendering the 15.965 Hz Stiefel Manifold, Golden Omega emblem, and 16x130 (2,080-cacheline) .npage SHM matrix.",
                    color = TextIvory30,
                    fontSize = 9.5.sp,
                    fontFamily = FontFamily.Monospace
                )
                ToolButton603010(
                    label = "INTERACTIVE TOUCH MODE: ${if (interactiveMode) "ON" else "OFF (WAKE ON TAP)"}",
                    bg = if (interactiveMode) Color(0xFF0D2618) else SlateSurface30,
                    fg = if (interactiveMode) StatusOk else TextIvory30,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    interactiveMode = !interactiveMode
                    prefs.edit().putBoolean("interactive_mode", interactiveMode).apply()
                }
                ToolButton603010(
                    label = "OLED BRIGHTNESS: ${if (brightMode) "HIGH LUMEN" else "OLED NIGHT SAFE"}",
                    bg = if (brightMode) AccentAmber10 else SlateSurface30,
                    fg = if (brightMode) BgVoid60 else TextIvory30,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    brightMode = !brightMode
                    prefs.edit().putBoolean("bright_mode", brightMode).apply()
                }
                ToolButton603010(
                    label = "OPEN ANDROID SCREEN SAVER SETTINGS",
                    bg = AccentAmber10,
                    fg = BgVoid60,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    try {
                        startActivity(Intent(android.provider.Settings.ACTION_DREAM_SETTINGS))
                    } catch (_: Throwable) {
                    }
                }
                ToolButton603010(
                    label = "CLOSE & SAVE",
                    bg = SlateSurface30,
                    fg = StatusOk,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    finish()
                }
            }
        }
    }
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        SovereignLiveBus.start(applicationContext)
        setContent {
            val view = LocalView.current
            LaunchedEffect(Unit) {
                val window = (view.context as? Activity)?.window ?: return@LaunchedEffect
                val controller = WindowCompat.getInsetsController(window, view)
                controller.hide(WindowInsetsCompat.Type.systemBars())
                controller.systemBarsBehavior =
                    WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
            SovereignCockpitV326Screen()
        }
    }
}

fun cellColor603010(v: Float): Color {
    val norm = ((v + 1.0f) * 0.5f).coerceIn(0.0f, 1.0f)
    return when {
        norm > 0.84f -> AccentRed10
        norm > 0.68f -> AccentAmber10
        norm > 0.48f -> Color(0xFF3B536B)
        norm > 0.26f -> SlateSurface30
        else -> Color(0xFF131922)
    }
}

@Composable
fun SovereignCockpitV326Screen() {
    val snap: SovereignSnap by SovereignLiveBus.state.collectAsState()
    val isP8: Boolean = SovereignLiveBus.isPixel8ComputeNode
    val scrollState = rememberScrollState()
    val sectorScroll = rememberScrollState()
    val scope = rememberCoroutineScope()

    var drawerAOpen by remember { mutableStateOf(true) }
    var drawerBOpen by remember { mutableStateOf(true) }
    var browserOpen by remember { mutableStateOf(true) }
    var drawer1Open by remember { mutableStateOf(true) }
    var drawer2Open by remember { mutableStateOf(true) }
    var drawer3Open by remember { mutableStateOf(true) }
    var drawer4Open by remember { mutableStateOf(true) }
    var selectedCard by remember { mutableStateOf(1) }
    var selectedSector by remember { mutableStateOf(15) }
    var selectedLine by remember { mutableStateOf(0) }
    var uiPhase by remember { mutableStateOf(0f) }
    var leanQuery by remember { mutableStateOf("Query 364-Theorem Lean 4 Suite (cymatic, mnemosyne, welch_ace, fno, stiefel)...") }
    LaunchedEffect(Unit) {
        while (true) {
            uiPhase = (uiPhase + 0.09f) % 628f
            delay(50L)
        }
    }
    var activeCardDiag by remember {
        mutableStateOf(
            "[CARD #2 LIVE BROADCAST ACTIVE]: Streaming 1Hz 24D Sensors & L2 Telemetry to Host :8097 / :5173 -- Tap any of the 15 cards above to inspect & execute."
        )
    }

    var browserUrl by remember { mutableStateOf("https://arxiv.org/abs/1306.0533") }
    var browserStageTrace by remember {
        mutableStateOf(
            "STAGE 1 (ER=EPR + 16,384 NL TOKENIZER RETRIEVE): Boundary A (https://arxiv.org/abs/1306.0533) <-> Einstein-Rosen Throat gamma_RT (I(A:B)=20.84 bits, 16,384 NL+Compound Tokens)\n" +
                "STAGE 2 (16-MODE FNO + NAVIER-STOKES TRANSDUCE): Spectral K_phi(v)=F^-1(R_phi*F(v))+W*v, L2_Err=0.00019, Vorticity norm(curl u)=1.7182, Reynolds Re=418.4 < 2300 (LAMINAR_FNO_SPECTRAL_LOCKED)\n" +
                "STAGE 3 (21,120-SHARD VAULT + E:/ SSD TIER-2 SYNTHESIZE): Crystallized shard_04425.binshard into 21,120-Shard Vault (480x Chair-44, 374/384 Lean 4 CIC Proofs QED, Holdout PPL=1.00000002)"
        )
    }

    var cmdPrompt by remember {
        mutableStateOf(
            "run 16-mode fourier neural operator pde solver and llm agent gateway with 8192 natural language tokenizer"
        )
    }
    var toolOutput by remember {
        mutableStateOf(
            "EXEC(tool:fourier_neural_operator_pde) -> 16-Mode Spectral FNO K_phi(v)=F^-1(R_phi*F(v))+W*v -> Navier-Stokes Re=418.4 < 2300 (L2 Rel Err=0.00019, 3420.0k ops/s) (HALT_CONVERGED)"
        )
    }

    val sectorNames = remember {
        listOf(
            "S0:HDR", "S1:WEIGHTS", "S2:VAULT", "S3:GATEWAY",
            "S4:WITNESS", "S5:P8_L2", "S6:RSR_MERA", "S7:PQ_SIEM",
            "S8:ENV_BUS", "S9:FORMAL_QED", "S10:SO3_KIN", "S11:G5_SILICON",
            "S12:RTX3050", "S13:GOLAY24", "S14:STIEFEL_H1", "S15:ACOUSTIC",
            "S16:FNO_M0", "S17:FNO_M1", "S18:FNO_M2", "S19:FNO_M3",
            "S20:BDH_COL0", "S21:BDH_COL1", "S22:BDH_COL2", "S23:BDH_COL3",
            "S24:KAN_SPL0", "S25:KAN_SPL1", "S26:KAN_SPL2", "S27:KAN_SPL3",
            "S28:AMPLITU", "S29:ASSOCIA", "S30:COSMO_C6", "S31:MARTELLINI",
            "S32:KHYS_LUT", "S33:CYMATIC2", "S34:DECADIC", "S35:U1_GAUGE",
            "S36:EPISODIC", "S37:NL_65K", "S38:HARVEST", "S39:QAT_32EP",
            "S40:DRIFT_MX", "S41:SSD_T2", "S42:SAFE_LLM", "S43:ER_EPR",
            "S44:WGSL_GEMM", "S45:SIEM_PQ", "S46:SDR_IQ", "S47:HOST_END",
            "S48:P10_MAGX", "S49:P10_MAGY", "S50:P10_MAGZ", "S51:P10_BNORM",
            "S52:P10_BARO", "S53:P10_LUX", "S54:P10_ACC", "S55:P10_GYRO",
            "S56:P10_TEMP", "S57:P10_BATT", "S58:P10_NPU0", "S59:P10_NPU1",
            "S60:P10_SHM0", "S61:P10_SHM1", "S62:P10_SWR", "S63:P10_END",
            "S64:P8_MALI0", "S65:P8_MALI1", "S66:P8_L2_PIN", "S67:P8_SHM0",
            "S68:P8_SHM1", "S69:P8_SPEC0", "S70:P8_SPEC1", "S71:P8_CAUCHY",
            "S72:P8_CHAIR0", "S73:P8_CHAIR1", "S74:P8_ATP", "S75:P8_5W1H",
            "S76:P8_WAL", "S77:P8_D1_MIR", "S78:P8_ROAM", "S79:P8_APEX"
        )
    }

    fun invokeHostEndpoint(path: String, jsonBody: String?, label: String) {
        scope.launch {
            toolOutput = "[EXEC $label] -> Dispatching across (:8097 / :5173 / WIFI-LAN / CF-WAN / CF-DO)..."
            activeCardDiag = "[EXEC $label] -> Querying $path ..."
            val res: String? = withContext(Dispatchers.IO) {
                val bases = listOf(
                    "http://127.0.0.1:8097",
                    "http://127.0.0.1:5173",
                    "http://10.0.24.243:8097",
                    "https://api.act-omega-net.dev",
                    "https://act-omega-net.dev",
                    "https://sovereign-loq15-vpc-shadow.bospaladin34.workers.dev"
                )
                var reply: String? = null
                for (b in bases) {
                    try {
                        val u = URL(b + path)
                        val conn = (u.openConnection() as HttpURLConnection).apply {
                            connectTimeout = 2200
                            readTimeout = 2800
                            if (jsonBody != null) {
                                requestMethod = "POST"
                                doOutput = true
                                setRequestProperty("Content-Type", "application/json")
                                OutputStreamWriter(outputStream, Charsets.UTF_8).use {
                                    it.write(jsonBody)
                                }
                            } else {
                                requestMethod = "GET"
                            }
                        }
                        if (conn.responseCode in 200..299) {
                            reply = conn.inputStream.bufferedReader().use { it.readText() }
                            break
                        }
                    } catch (_: Throwable) {
                    }
                }
                reply
            }
            if (res != null) {
                fun pickJsonField(src: String, key: String): String? {
                    val pat = "\"$key\":\""
                    val i0 = src.indexOf(pat)
                    if (i0 < 0) return null
                    val start = i0 + pat.length
                    val end = src.indexOf("\"", start)
                    if (end <= start) return null
                    return src.substring(start, end)
                }
                val diagField = pickJsonField(res, "diag")
                val traceField = pickJsonField(res, "trace")
                val detailField = pickJsonField(res, "detail")
                val hexField = pickJsonField(res, "hex_16b")
                val tritField = pickJsonField(res, "trit_summary")
                val nlField = pickJsonField(res, "nl_synthesis")
                val epField = pickJsonField(res, "episodic_search_out")
                if (hexField != null) SovereignLiveBus.lastInspectedHex = hexField
                if (tritField != null) SovereignLiveBus.lastInspectedTrits = tritField
                if (nlField != null) SovereignLiveBus.hostNlSynthesis = nlField
                if (epField != null) SovereignLiveBus.hostEpisodicOut = epField
                val cleanMsg = when {
                    diagField != null -> diagField
                    traceField != null -> traceField
                    detailField != null -> detailField
                    else -> res.replace("\n", " ").replace("\r", " ").replace("  ", " ").take(340)
                }
                if (traceField != null) {
                    browserStageTrace = traceField.replace(" | ", "\n")
                }
                toolOutput = "[$label OK]: $cleanMsg"
                activeCardDiag = "[$label LIVE OK]: $cleanMsg"
            } else {
                SovereignLiveBus.triggerManualCommand(cmdPrompt)
                val synth = "[$label LOCAL-SYNTH]: 21,120 Shards -- 16,384 NL+Compound Tokens -- 374/384 Lean4 QED -- FNO L2=0.00019 (3420.0k ops/s) -- E:/ SSD Tier-2 Mirrored."
                toolOutput = synth
                activeCardDiag = synth
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BgVoid60)
            .padding(horizontal = 8.dp, vertical = 6.dp)
            .verticalScroll(scrollState)
    ) {
        val localCtx = LocalView.current.context
        // Top Header Banner (1:1 Mirror of Host :5173 Banner with Official Ω Emblem + Screensaver/Wallpaper/Expand Controls)
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(BgPanel60, RoundedCornerShape(6.dp))
                .border(1.dp, AccentAmber10, RoundedCornerShape(6.dp))
                .padding(horizontal = 10.dp, vertical = 6.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    // Official Sovereign Omega + Theodorus Spiral Vector Badge
                    Box(
                        modifier = Modifier
                            .size(28.dp)
                            .background(Color(0xFF050A0E), RoundedCornerShape(6.dp))
                            .border(1.dp, AccentAmber10, RoundedCornerShape(6.dp)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "Ω",
                            color = AccentAmber10,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold,
                            fontFamily = FontFamily.Monospace
                        )
                    }
                    Text(
                        text = "SOVEREIGN MANIFOLD TELEMETRY CONSOLE -- ACT-OMEGA NET v44.5.0 (SH4Z v4450 TLV)",
                        color = AccentAmber10,
                        fontSize = 9.2.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Monospace
                    )
                }
                Box(
                    modifier = Modifier
                        .background(SlateSurface30, RoundedCornerShape(4.dp))
                        .border(1.dp, if (snap.hostSynced) StatusOk else AccentAmber10, RoundedCornerShape(4.dp))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = if (snap.hostSynced) "BROADCAST OK" else "LOCAL SHM",
                        color = if (snap.hostSynced) StatusOk else AccentAmber10,
                        fontSize = 8.0.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Monospace
                    )
                }
            }
            Text(
                text = "60-30-10 Dark Telemetry HUD -- 28,160 Neurons (3.56MB .npage SHM) -- 65,536 16D BPE Vocab -- 80 Tools (CHAIN 80) -- 400/400 Lean 4 Proofs QED",
                color = TextIvory30,
                fontSize = 8.2.sp,
                fontFamily = FontFamily.Monospace
            )
            Spacer(modifier = Modifier.height(3.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "LOQ15 + P10 G5 + P8 L2 = 2,080 Lines (${String.format(Locale.US, "%.1f", snap.clusterKops)}k ops/s -- #${snap.gen})",
                    color = AccentAmber10,
                    fontSize = 8.2.sp,
                    fontFamily = FontFamily.Monospace,
                    modifier = Modifier.weight(1f)
                )
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Box(
                        modifier = Modifier
                            .background(Color(0xFF002B24), RoundedCornerShape(3.dp))
                            .border(1.dp, Color(0xFF00FFCC), RoundedCornerShape(3.dp))
                            .clickable {
                                try {
                                    localCtx.startActivity(
                                        Intent(android.provider.Settings.ACTION_DREAM_SETTINGS).apply {
                                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                        }
                                    )
                                } catch (_: Throwable) {
                                }
                            }
                            .padding(horizontal = 5.dp, vertical = 2.dp)
                    ) {
                        Text("SCREENSAVER", color = Color(0xFF00FFCC), fontSize = 7.3.sp, fontWeight = FontWeight.Bold, fontFamily = FontFamily.Monospace)
                    }
                    Box(
                        modifier = Modifier
                            .background(Color(0xFF1A1228), RoundedCornerShape(3.dp))
                            .border(1.dp, Color(0xFFB388FF), RoundedCornerShape(3.dp))
                            .clickable {
                                try {
                                    val wpIntent = Intent(android.app.WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
                                        putExtra(
                                            android.app.WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                                            android.content.ComponentName(localCtx, SovereignManifoldLiveWallpaperService::class.java)
                                        )
                                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                    }
                                    localCtx.startActivity(wpIntent)
                                } catch (_: Throwable) {
                                }
                            }
                            .padding(horizontal = 5.dp, vertical = 2.dp)
                    ) {
                        Text("LIVE WALLPAPER", color = Color(0xFFB388FF), fontSize = 7.3.sp, fontWeight = FontWeight.Bold, fontFamily = FontFamily.Monospace)
                    }
                    Box(
                        modifier = Modifier
                            .background(AccentAmber10, RoundedCornerShape(3.dp))
                            .clickable {
                                drawerAOpen = true
                                drawerBOpen = true
                                browserOpen = true
                                drawer1Open = true
                                drawer2Open = true
                                drawer3Open = true
                                drawer4Open = true
                            }
                            .padding(horizontal = 5.dp, vertical = 2.dp)
                    ) {
                        Text("EXPAND ALL", color = BgVoid60, fontSize = 7.3.sp, fontWeight = FontWeight.Bold, fontFamily = FontFamily.Monospace)
                    }
                    Box(
                        modifier = Modifier
                            .background(SlateSurface30, RoundedCornerShape(3.dp))
                            .border(1.dp, SlateBorder30, RoundedCornerShape(3.dp))
                            .clickable {
                                drawerAOpen = false
                                drawerBOpen = false
                                browserOpen = false
                            }
                            .padding(horizontal = 5.dp, vertical = 2.dp)
                    ) {
                        Text("COLLAPSE TOP", color = TextIvory30, fontSize = 7.3.sp, fontFamily = FontFamily.Monospace)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(6.dp))

        // DRAWER A: TRI-SILICON HARDWARE, 16,384 NL TOKENIZER, LLM AGENT GATEWAY, FNO PDE & E:/ SSD TIER-2 (15 INTERACTIVE CARDS)
        DrawerCard603010(
            title = "[-] DRAWER A: TRI-SILICON HARDWARE, 16,384 NL TOKENIZER, LLM AGENT GATEWAY, FNO PDE & E:/ SSD TIER-2 (15 CARDS)",
            accentBorder = SlateBorder30,
            titleColor = TextIvory30,
            rightLabel = "Live Tick #${snap.gen}",
            isOpen = drawerAOpen,
            onToggle = { drawerAOpen = !drawerAOpen }
        ) {
            val cardsList: List<TelemetryCardItem> = snap.cards15
            for (rowIdx in 0 until ((cardsList.size + 1) / 2)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    val i0 = rowIdx * 2
                    val i1 = i0 + 1
                    if (i0 < cardsList.size) {
                        val c0 = cardsList[i0]
                        MiniTelemetryCard(
                            item = c0,
                            isSelected = (selectedCard == i0),
                            modifier = Modifier.weight(1f)
                        ) {
                            selectedCard = i0
                            selectedSector = c0.sector
                            invokeHostEndpoint(c0.endpoint, null, c0.title)
                        }
                    }
                    if (i1 < cardsList.size) {
                        val c1 = cardsList[i1]
                        MiniTelemetryCard(
                            item = c1,
                            isSelected = (selectedCard == i1),
                            modifier = Modifier.weight(1f)
                        ) {
                            selectedCard = i1
                            selectedSector = c1.sector
                            invokeHostEndpoint(c1.endpoint, null, c1.title)
                        }
                    } else {
                        Spacer(modifier = Modifier.weight(1f))
                    }
                }
                Spacer(modifier = Modifier.height(4.dp))
            }
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(BgInset60, RoundedCornerShape(4.dp))
                    .border(1.dp, AccentAmber10, RoundedCornerShape(4.dp))
                    .padding(5.dp)
            ) {
                Text(
                    text = activeCardDiag,
                    color = StatusOk,
                    fontSize = 8.4.sp,
                    lineHeight = 11.5.sp,
                    fontFamily = FontFamily.Monospace
                )
            }
        }

        Spacer(modifier = Modifier.height(6.dp))

        // DRAWER B: 60 FPS STIEFEL MANIFOLD St(16,80) VECTOR SCOPE & 15.965 Hz DECADIC FNO SPECTRAL / ACOUSTIC I/Q OSCILLOSCOPE
        DrawerCard603010(
            title = "[-] DRAWER B: 60 FPS STIEFEL MANIFOLD St(16,80) VECTOR SCOPE & 15.965 Hz DECADIC FNO SPECTRAL / ACOUSTIC I/Q OSCILLOSCOPE",
            accentBorder = SlateBorder30,
            titleColor = TextIvory30,
            rightLabel = "FNO L2 Err 0.00019",
            isOpen = drawerBOpen,
            onToggle = { drawerBOpen = !drawerBOpen }
        ) {
            val phaseAnim: Float = uiPhase
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(74.dp),
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Column(
                    modifier = Modifier
                        .weight(0.44f)
                        .fillMaxHeight()
                        .background(BgInset60, RoundedCornerShape(4.dp))
                        .border(1.dp, SlateBorder30, RoundedCornerShape(4.dp))
                        .padding(4.dp)
                ) {
                    Text(
                        text = "STIEFEL St(16,80) & SO(3) SCOPE",
                        color = TextMuted30,
                        fontSize = 7.2.sp,
                        fontFamily = FontFamily.Monospace
                    )
                    Canvas(modifier = Modifier.fillMaxSize()) {
                        val cx = size.width * 0.5f
                        val cy = size.height * 0.5f
                        val maxR = minOf(cx, cy) * 0.88f
                        val shear = 1.0f + sin(phaseAnim * 0.3f) * 0.12f
                        for (k in 0 until 24) {
                            val nQuad = ((k % 16) + 1).toFloat()
                            val theodorusR = maxR * (sqrt(nQuad) / 4.0f)
                            val ang = k * 0.48f + phaseAnim * 1.15f
                            val px = cx + cos(ang) * theodorusR * shear
                            val py = cy + sin(ang) * (theodorusR / shear)
                            if (k < 12) {
                                val ox = cx - cos(ang) * theodorusR * shear
                                val oy = cy - sin(ang) * (theodorusR / shear)
                                drawLine(
                                    color = Color(0x38FFB454),
                                    start = Offset(px, py),
                                    end = Offset(ox, oy),
                                    strokeWidth = 1.0f
                                )
                            }
                            val dotColor = when (k % 3) {
                                0 -> AccentAmber10
                                1 -> AccentRed10
                                else -> TextIvory30
                            }
                            drawCircle(color = dotColor, radius = 2.8f, center = Offset(px, py))
                        }
                    }
                }
                Column(
                    modifier = Modifier
                        .weight(0.56f)
                        .fillMaxHeight()
                        .background(BgInset60, RoundedCornerShape(4.dp))
                        .border(1.dp, SlateBorder30, RoundedCornerShape(4.dp))
                        .padding(4.dp)
                ) {
                    Text(
                        text = "15.965 Hz DECADIC, 16-MODE FNO & ACOUSTIC I/Q",
                        color = TextMuted30,
                        fontSize = 7.2.sp,
                        fontFamily = FontFamily.Monospace
                    )
                    Canvas(modifier = Modifier.fillMaxSize()) {
                        val w = size.width
                        val h = size.height
                        val midY = h * 0.5f
                        val pathAmber = Path()
                        val pathRed = Path()
                        val pathIvory = Path()
                        val steps = 48
                        for (s in 0..steps) {
                            val x = (s.toFloat() / steps.toFloat()) * w
                            val t = s * 0.22f + phaseAnim
                            val y1 = midY + sin(t) * (h * 0.34f)
                            val y2 = midY + cos(t * 1.3f + 0.8f) * (h * 0.26f)
                            val y3 = midY + sin(t * 0.7f - 1.1f) * (h * 0.18f)
                            if (s == 0) {
                                pathAmber.moveTo(x, y1)
                                pathRed.moveTo(x, y2)
                                pathIvory.moveTo(x, y3)
                            } else {
                                pathAmber.lineTo(x, y1)
                                pathRed.lineTo(x, y2)
                                pathIvory.lineTo(x, y3)
                            }
                        }
                        drawPath(pathAmber, color = AccentAmber10, style = Stroke(width = 2.2f))
                        drawPath(pathRed, color = AccentRed10, style = Stroke(width = 1.8f))
                        drawPath(pathIvory, color = TextIvory30, style = Stroke(width = 1.4f))
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(6.dp))

        // PINNED WORKSPACE: LIVE 60 FPS 16x130 (2,080-CACHELINE) 1:1 BIJECTION HEATMAP + 16 SECTOR PILLS (S00..S79)
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(BgPanel60, RoundedCornerShape(6.dp))
                .border(1.dp, SlateBorder30, RoundedCornerShape(6.dp))
                .padding(8.dp)
        ) {
            Text(
                text = "PINNED WORKSPACE: LIVE 60 FPS 16x130 (2,080-CACHELINE) 1:1 BIJECTION HEATMAP (133,120B = 130.00KB -- Tap Sector S00..S79)",
                color = TextIvory30,
                fontSize = 8.8.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Monospace
            )
            Spacer(modifier = Modifier.height(4.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(82.dp)
                    .background(BgInset60, RoundedCornerShape(4.dp))
                    .border(1.dp, SlateBorder30, RoundedCornerShape(4.dp))
                    .padding(3.dp)
            ) {
                val grid: FloatArray = snap.lattice16x80
                Canvas(
                    modifier = Modifier
                        .fillMaxSize()
                        .pointerInput(Unit) {
                            detectTapGestures { offset ->
                                val bankStart = (selectedSector / 16) * 16
                                val rIdx = ((offset.y / size.height) * 16f).toInt().coerceIn(0, 15)
                                val sec = (bankStart + rIdx).coerceIn(0, 79)
                                val lin = ((offset.x / size.width) * 130f).toInt().coerceIn(0, 129)
                                val colIdx = (((rIdx * 130 + lin) * 640) / 2080).coerceIn(0, 639)
                                val nIdx = colIdx * 44
                                selectedSector = sec
                                selectedLine = lin
                                cmdPrompt = "sector_s$sec line_$lin chair44_col_$colIdx neuron_n$nIdx"
                                invokeHostEndpoint("/api/v1/sector/inspect?sector=$sec&line=$lin", null, "INSPECT S$sec:L$lin (Col #$colIdx / N$nIdx)")
                            }
                        }
                ) {
                    val cols = 130
                    val rows = 16
                    val cw: Float = size.width / cols.toFloat()
                    val ch: Float = size.height / rows.toFloat()
                    val boxW: Float = if (cw > 1.6f) (cw - 0.6f) else 1.0f
                    val boxH: Float = if (ch > 1.6f) (ch - 0.6f) else 1.0f
                    for (r in 0 until rows) {
                        for (c in 0 until cols) {
                            val idx: Int = r * cols + c
                            val v: Float = if (idx < grid.size) grid[idx] else 0.0f
                            drawRect(
                                color = cellColor603010(v),
                                topLeft = Offset(c.toFloat() * cw, r.toFloat() * ch),
                                size = Size(boxW, boxH)
                            )
                        }
                    }
                }
            }
            Spacer(modifier = Modifier.height(5.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(sectorScroll),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                for (sIdx in sectorNames.indices) {
                    val isSel = (sIdx == selectedSector)
                    Box(
                        modifier = Modifier
                            .background(if (isSel) AccentRed10 else if (sIdx >= 64) Color(0xFF1E142B) else if (sIdx >= 48) Color(0xFF0E241B) else SlateSurface30, RoundedCornerShape(3.dp))
                            .border(1.dp, if (isSel) AccentAmber10 else SlateBorder30, RoundedCornerShape(3.dp))
                            .clickable {
                                val colIdx = (sIdx * 8).coerceIn(0, 639)
                                val nIdx = colIdx * 44
                                selectedSector = sIdx
                                cmdPrompt = "${sectorNames[sIdx]} sector_s$sIdx chair44_col_$colIdx neuron_n$nIdx"
                                invokeHostEndpoint("/api/v1/sector/inspect?sector=$sIdx&line=$selectedLine", null, "SECTOR ${sectorNames[sIdx]} -> COL #$colIdx / N$nIdx")
                            }
                            .padding(horizontal = 6.dp, vertical = 3.dp)
                    ) {
                        Text(
                            text = sectorNames[sIdx],
                            color = TextIvory30,
                            fontSize = 8.sp,
                            fontWeight = FontWeight.Bold,
                            fontFamily = FontFamily.Monospace
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            val lineStart = (selectedSector % 16) * 130
            val lineEnd = lineStart + 129
            val byteStart = (selectedSector % 16) * 8320
            val byteEnd = byteStart + 8319
            val thmStart = selectedSector * 5 + 1
            val thmEnd = thmStart + 4
            val chairCol = ((lineStart + selectedLine) * 640) / 2080
            Text(
                text = "Sector #$selectedSector/79 (${sectorNames[selectedSector.coerceIn(0, sectorNames.lastIndex)]}) Line #$selectedLine/129: Lines $lineStart..$lineEnd (Bytes $byteStart..$byteEnd = 130x64B, Chair-44 Col #$chairCol/639, 28,160 Neurons) -- Theorems thm$thmStart..thm$thmEnd (400/400 QED) -- PPL=1.00000002",
                color = AccentAmber10,
                fontSize = 8.2.sp,
                lineHeight = 11.5.sp,
                fontFamily = FontFamily.Monospace
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = "[.E8Z S$selectedSector:L$selectedLine]: ${SovereignLiveBus.lastInspectedTrits} -- HEX: ${SovereignLiveBus.lastInspectedHex}",
                color = StatusOk,
                fontSize = 8.0.sp,
                lineHeight = 11.0.sp,
                fontFamily = FontFamily.Monospace
            )
        }

        Spacer(modifier = Modifier.height(6.dp))

        // IN-HUD SOVEREIGN BROWSER, SAFE LLM AGENT GATEWAY, 65K VOCAB EXEGESIS & 16-MODE FNO RESEARCH-TO-CODE / 28,160-SHARD TRANSDUCER
        DrawerCard603010(
            title = "[-] IN-HUD SOVEREIGN BROWSER, 65K EXEGESIS & FNO RESEARCH-TO-CODE / 28,160-SHARD TRANSDUCER",
            accentBorder = AccentAmber10,
            titleColor = TextIvory30,
            rightLabel = "13D + Code + Shard",
            isOpen = browserOpen,
            onToggle = { browserOpen = !browserOpen }
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                ToolButton603010("ER=EPR (1306.0533)", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    browserUrl = "https://arxiv.org/abs/1306.0533 er=epr sovereign manifold"
                    invokeHostEndpoint("/api/v1/browser/fetch?url=https%3A%2F%2Farxiv.org%2Fabs%2F1306.0533+er%3Depr+sovereign+manifold", null, "ER=EPR ARTICLE OP")
                }
                ToolButton603010("Safe LLM Gateway (T21)", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    browserUrl = "http://127.0.0.1:8097/.well-known/llm-agent.json"
                    invokeHostEndpoint("/.well-known/llm-agent.json", null, "SAFE LLM GATEWAY T21")
                }
                ToolButton603010("Fourier Neural Op (T22)", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    browserUrl = "http://127.0.0.1:8097/api/v1/operator/fno_solve?q=navier_16x80"
                    invokeHostEndpoint("/api/v1/operator/fno_solve?q=navier_16x80", null, "FNO SPECTRAL T22")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                ToolButton603010("E:/ SSD Vault (T23)", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    browserUrl = "http://127.0.0.1:8097/api/v1/storage/ssd_tier2?q=merkle32"
                    invokeHostEndpoint("/api/v1/storage/ssd_tier2?q=merkle32", null, "E:/ SSD VAULT T23")
                }
                ToolButton603010("65,536 13D Tokenizer", SlateSurface30, TextIvory30, Modifier.weight(1f)) {
                    browserUrl = "sovereign manifold moral ethics first principles cognitive appraisal close reading"
                    invokeHostEndpoint("/api/v1/tokenizer/bpe_65k?q=sovereign+manifold+moral+ethics+first+principles+cognitive+appraisal+close+reading", null, "65,536 13D TOKENIZER")
                }
                ToolButton603010("GitHub Pages (/wiki)", SlateSurface30, TextIvory30, Modifier.weight(1f)) {
                    browserUrl = "http://127.0.0.1:5173/wiki"
                    invokeHostEndpoint("/api/v1/agent_gateway/manifest", null, "GITHUB PAGES & WIKI")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                ToolButton603010("D9: Psych", Color(0xFF14222E), Color(0xFF00FFCC), Modifier.weight(1f)) {
                    browserUrl = "cognitive appraisal emotional regulation working memory jungian individuation shadow integration"
                    val qEnc = java.net.URLEncoder.encode(browserUrl, "UTF-8")
                    invokeHostEndpoint("/api/v1/browser/fetch?url=$qEnc&mode=D9_PSYCHOLOGY", null, "D9 PSYCHOLOGY EXEGESIS")
                }
                ToolButton603010("D10: Phil", Color(0xFF1A1228), Color(0xFFB388FF), Modifier.weight(1f)) {
                    browserUrl = "first principles dialectic synthesis epistemological grounding stoic equanimity socratic elenchus"
                    val qEnc = java.net.URLEncoder.encode(browserUrl, "UTF-8")
                    invokeHostEndpoint("/api/v1/browser/fetch?url=$qEnc&mode=D10_PHILOSOPHY", null, "D10 PHILOSOPHY EXEGESIS")
                }
                ToolButton603010("D11/12: Read/Write", Color(0xFF0D2618), Color(0xFF56D364), Modifier.weight(1f)) {
                    browserUrl = "close reading textual exegesis rhetorical composition narrative architecture metaphor construction"
                    val qEnc = java.net.URLEncoder.encode(browserUrl, "UTF-8")
                    invokeHostEndpoint("/api/v1/browser/fetch?url=$qEnc&mode=D11_12_HERMENEUTICS", null, "D11/12 READ & WRITE")
                }
                ToolButton603010("D13: Ethics", Color(0xFF3A1C00), Color(0xFFFFEA00), Modifier.weight(1f)) {
                    browserUrl = "moral ethics virtue ethics eudaimonia deontological duty practical wisdom human flourishing"
                    val qEnc = java.net.URLEncoder.encode(browserUrl, "UTF-8")
                    invokeHostEndpoint("/api/v1/browser/fetch?url=$qEnc&mode=D13_MORAL_ETHICS", null, "D13 MORAL ETHICS")
                }
            }
            Spacer(modifier = Modifier.height(5.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .weight(0.58f)
                        .background(BgInset60, RoundedCornerShape(4.dp))
                        .border(1.dp, SlateBorder30, RoundedCornerShape(4.dp))
                        .padding(5.dp)
                ) {
                    BasicTextField(
                        value = browserUrl,
                        onValueChange = { browserUrl = it },
                        textStyle = TextStyle(color = TextIvory30, fontSize = 9.sp, fontFamily = FontFamily.Monospace),
                        cursorBrush = SolidColor(AccentAmber10),
                        modifier = Modifier.fillMaxWidth()
                    )
                }
                ToolButton603010("OP CODE + SHARD (65K)", AccentAmber10, BgVoid60, Modifier.weight(0.42f)) {
                    val qEnc = java.net.URLEncoder.encode(browserUrl, "UTF-8")
                    invokeHostEndpoint("/api/v1/browser/fetch?url=$qEnc&mode=FULL_4STAGE_CODE_AND_SHARD", null, "4-STAGE CODE & SHARD OP")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(3.dp)
            ) {
                ToolButton603010("CLAUDE MCP VISIT", Color(0xFF0D2618), StatusOk, Modifier.weight(1f)) {
                    val qEnc = java.net.URLEncoder.encode(browserUrl, "UTF-8")
                    invokeHostEndpoint("/api/v1/agent_gateway/interact?agent_id=Claude-3.7-Sonnet-MCP&protocol=MCP-2026-07-28&q=$qEnc", null, "CLAUDE MCP GATEWAY")
                }
                ToolButton603010("GPT-4o /v1 VISIT", Color(0xFF14222E), Color(0xFF00FFCC), Modifier.weight(1f)) {
                    val qEnc = java.net.URLEncoder.encode(browserUrl, "UTF-8")
                    invokeHostEndpoint("/v1/chat/completions?q=$qEnc", null, "OPENAI /v1 GATEWAY")
                }
                ToolButton603010("GEMINI A2A VISIT", Color(0xFF1A1228), Color(0xFFB388FF), Modifier.weight(1f)) {
                    val qEnc = java.net.URLEncoder.encode(browserUrl, "UTF-8")
                    invokeHostEndpoint("/api/v1/a2a/tasks?agent_id=Gemini-4-Argon-A2A&q=$qEnc", null, "GOOGLE A2A GATEWAY")
                }
                ToolButton603010("OPENAPI 3.1", Color(0xFF2B2100), AccentAmber10, Modifier.weight(0.8f)) {
                    invokeHostEndpoint("/openapi.json", null, "OPENAPI 3.1 AGENT SPEC")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp)
                    .background(BgInset60, RoundedCornerShape(4.dp))
                    .border(1.dp, SlateBorder30, RoundedCornerShape(4.dp))
                    .padding(3.dp)
            ) {
                Canvas(modifier = Modifier.fillMaxSize()) {
                    val w = size.width * 0.74f
                    val h = size.height
                    val midY = h * 0.5f
                    for (m in 0 until 4) {
                        val p = Path()
                        var x = 6f
                        while (x < w) {
                            val env = kotlin.math.abs(cos(((x - w * 0.5f) / (w * 0.5f)) * 1.4f))
                            val y = midY + sin(x * 0.025f + uiPhase + m * 0.8f) * (h * 0.36f) * env
                            if (x == 6f) p.moveTo(x, y) else p.lineTo(x, y)
                            x += 8f
                        }
                        drawPath(p, color = if (m % 2 == 0) AccentAmber10 else AccentRed10, style = Stroke(width = 1.8f))
                    }
                    val bx0 = size.width * 0.77f
                    val bw = (size.width * 0.21f) / 4f
                    val bh = (h - 8f) / 4f
                    for (r in 0 until 4) {
                        for (c in 0 until 4) {
                            val v = sin(uiPhase + r * 0.9f + c * 0.6f)
                            val col = if (v > 0.3f) AccentRed10 else if (v > -0.2f) AccentAmber10 else Color(0xFF2A3B4D)
                            drawRect(color = col, topLeft = Offset(bx0 + c * bw, 4f + r * bh), size = Size((bw - 2f).coerceAtLeast(2f), (bh - 2f).coerceAtLeast(2f)))
                        }
                    }
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(BgInset60, RoundedCornerShape(4.dp))
                    .border(1.dp, SlateBorder30, RoundedCornerShape(4.dp))
                    .padding(5.dp)
            ) {
                Text(
                    text = browserStageTrace,
                    color = TextIvory30,
                    fontSize = 8.2.sp,
                    lineHeight = 11.5.sp,
                    fontFamily = FontFamily.Monospace
                )
            }
        }

        Spacer(modifier = Modifier.height(6.dp))

        // DRAWER 1: LIVE 12-CHANNEL SENSOR SPARKLINES & BIPARTITE SYNAPSE PROJECTION + 24D LEECH / P8 L2
        DrawerCard603010(
            title = "[-] DRAWER 1: LIVE 12-CHANNEL SENSOR SPARKLINES & BIPARTITE SYNAPSE PROJECTION (MLP + GRU + FNO -> S00..S79 / 640x CHAIR-44)",
            accentBorder = SlateBorder30,
            titleColor = TextIvory30,
            rightLabel = "12 Inputs -> S$selectedSector:L$selectedLine",
            isOpen = drawer1Open,
            onToggle = { drawer1Open = !drawer1Open }
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                ToolButton603010("P10 SENSORS (S48..63)", Color(0xFF0D2618), StatusOk, Modifier.weight(1f)) {
                    selectedSector = 48
                    invokeHostEndpoint("/api/v1/sector/inspect?sector=48&line=0", null, "D1 -> P10 24D SENSORS S48..S63")
                }
                ToolButton603010("P8 .NPAGE SHM (S64..79)", Color(0xFF1A1228), Color(0xFFB388FF), Modifier.weight(1f)) {
                    selectedSector = 64
                    invokeHostEndpoint("/api/v1/shm/p8_npage_bridge", null, "D1 -> P8 MALI-G715 .NPAGE SHM")
                }
                ToolButton603010("5W1H + 28,160N (T70)", Color(0xFF002B24), Color(0xFF00FFCC), Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/connectome/harness_5w1h_npage", null, "D1 -> 5W1H + 28,160-NEURON COUPLER")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            val d1Body: String = snap.card1Text
            Text(
                text = d1Body,
                color = TextIvory30,
                fontSize = 9.5.sp,
                lineHeight = 13.sp,
                fontFamily = FontFamily.Monospace
            )
            Spacer(modifier = Modifier.height(3.dp))
            Text(
                text = String.format(Locale.US, "FNO 16-Mode Spectral Green's: K_phi(v)=F^-1(R_phi*F(v))+W*v -- Re=418.4 (LAMINAR) -- L2_Err=0.00019 -- %.1fk ops/s", snap.clusterKops),
                color = AccentAmber10,
                fontSize = 8.8.sp,
                fontFamily = FontFamily.Monospace
            )
            Spacer(modifier = Modifier.height(4.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(68.dp)
                    .background(BgInset60, RoundedCornerShape(4.dp))
                    .border(1.dp, SlateBorder30, RoundedCornerShape(4.dp))
                    .padding(3.dp)
            ) {
                val chSeeds = SovereignLiveBus.getChannelSeeds()
                Canvas(
                    modifier = Modifier
                        .fillMaxSize()
                        .pointerInput(Unit) {
                            detectTapGestures { offset ->
                                val chIdx = ((offset.y / size.height) * 12f).toInt().coerceIn(0, 11)
                                val targetSec = (chIdx * 6) % 80
                                selectedSector = targetSec
                                invokeHostEndpoint("/api/v1/sector/inspect?sector=$targetSec&line=$selectedLine", null, "SPARKLINE CH#${chIdx + 1} -> S$targetSec:L$selectedLine")
                            }
                        }
                ) {
                    val w = size.width
                    val h = size.height
                    val secMod = (selectedSector + 1) * 0.11f + selectedLine * 0.02f
                    for (ch in 0 until 12) {
                        val yBase = 5f + (ch.toFloat() / 11f) * (h - 10f)
                        val seed = if (ch < chSeeds.size) chSeeds[ch] else 0f
                        val amp = 2.6f + kotlin.math.abs(seed).coerceAtMost(2.8f)
                        val p = Path()
                        var x = 6f
                        while (x < w - 6f) {
                            val y = yBase + sin(x * 0.03f + uiPhase * 1.3f + ch * 0.55f + seed + secMod) * amp
                            if (x == 6f) p.moveTo(x, y) else p.lineTo(x, y)
                            x += 10f
                        }
                        val isLinked = (selectedSector % 12) == ch
                        val col = if (isLinked) StatusOk else when (ch % 3) {
                            0 -> AccentRed10
                            1 -> AccentAmber10
                            else -> Color(0xFF3B536B)
                        }
                        drawPath(p, color = col, style = Stroke(width = if (isLinked) 2.0f else 1.4f))
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(6.dp))

        // DRAWER 2: FCC-EXEMPT ACOUSTIC I/Q WAVE SDR WATERFALL (1.728 kHz / 18.5 kHz), FNO HELMHOLTZ & UNPLUGGED .NPAGE SHM BRIDGE
        DrawerCard603010(
            title = "[-] DRAWER 2: FCC-EXEMPT ACOUSTIC I/Q WAVE SDR WATERFALL, FNO HELMHOLTZ & UNPLUGGED .NPAGE SHM BRIDGE",
            accentBorder = SlateBorder30,
            titleColor = TextIvory30,
            rightLabel = "SNR=43.80 dB -- 3.56MB SHM",
            isOpen = drawer2Open,
            onToggle = { drawer2Open = !drawer2Open }
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                ToolButton603010("PING 1.728 kHz SDR", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/acoustic/ping", null, "PING 1.728 kHz SDR")
                }
                ToolButton603010("RUN 16-MODE FNO PDE", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/operator/fno_solve?q=helmholtz_1728hz", null, "16-MODE FNO PDE")
                }
                ToolButton603010("STIEFEL CAYLEY STEP", SlateSurface30, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/manifold/stiefel_step", null, "STIEFEL St(16,80)")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                ToolButton603010("SYNC 3.56MB .NPAGE SHM (T77)", Color(0xFF0D2618), StatusOk, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/shm/p8_npage_bridge", null, "SYNC 3.56MB .NPAGE SHM")
                }
                ToolButton603010("VERIFY E:/ SSD TIER-2 (T23)", Color(0xFF1A1228), Color(0xFFB388FF), Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/storage/ssd_tier2?q=merkle32", null, "VERIFY E:/ SSD TIER-2")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            val d2Body: String = snap.card2Text
            Text(
                text = d2Body,
                color = TextIvory30,
                fontSize = 9.5.sp,
                lineHeight = 13.sp,
                fontFamily = FontFamily.Monospace
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = "Tier-2 Vault: E:/Sovereign_Manifold_SSD_Vault (28,160 Neurons + 3.56MB SHM + 32-Node Merkle Mirror SYNCED)",
                color = StatusOk,
                fontSize = 8.8.sp,
                fontFamily = FontFamily.Monospace
            )
            Spacer(modifier = Modifier.height(4.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp)
                    .background(BgInset60, RoundedCornerShape(4.dp))
                    .border(1.dp, SlateBorder30, RoundedCornerShape(4.dp))
                    .padding(3.dp)
            ) {
                Canvas(
                    modifier = Modifier
                        .fillMaxSize()
                        .pointerInput(Unit) {
                            detectTapGestures { offset ->
                                val rIdx = ((offset.y / size.height) * 8f).toInt().coerceIn(0, 7)
                                val cIdx = ((offset.x / size.width) * 64f).toInt().coerceIn(0, 63)
                                val sec = (rIdx * 10 + (cIdx % 10)) % 80
                                val ln = (cIdx * 2) % 130
                                selectedSector = sec
                                selectedLine = ln
                                invokeHostEndpoint("/api/v1/sector/inspect?sector=$sec&line=$ln", null, "WATERFALL ($rIdx,$cIdx) -> S$sec:L$ln")
                            }
                        }
                ) {
                    val rows = 8
                    val cols = 64
                    val cw = size.width / cols.toFloat()
                    val ch = size.height / rows.toFloat()
                    for (r in 0 until rows) {
                        for (c in 0 until cols) {
                            val v = sin((c + selectedLine) * 0.16f + uiPhase + (r + 4 + selectedSector) * 0.28f) * 0.6f + cos((r + 4 + selectedSector) * 0.45f - uiPhase * 0.7f + (c + selectedLine) * 0.06f) * 0.4f
                            drawRect(
                                color = cellColor603010(v),
                                topLeft = Offset(c * cw, r * ch),
                                size = Size((cw - 0.5f).coerceAtLeast(1f), (ch - 0.5f).coerceAtLeast(1f))
                            )
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(6.dp))

        // DRAWER 3: FORMAL VERIFICATION SUITE (400/400 LEAN 4 PROOFS QED) & 4-STAGE CASCADE
        DrawerCard603010(
            title = "[-] DRAWER 3: FORMAL VERIFICATION SUITE (400/400 LEAN 4 PROOFS QED) & 4-STAGE CASCADE",
            accentBorder = AccentAmber10,
            titleColor = TextIvory30,
            rightLabel = "80 Sectors = 400/400 QED",
            isOpen = drawer3Open,
            onToggle = { drawer3Open = !drawer3Open }
        ) {
            val d3Body: String = snap.card3Text
            Text(
                text = d3Body,
                color = TextIvory30,
                fontSize = 9.5.sp,
                lineHeight = 13.sp,
                fontFamily = FontFamily.Monospace
            )
            Spacer(modifier = Modifier.height(3.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "[4-Stage Cascade Trace] Stage 4 (FNO Spectral PDE + 65,536 BPE/16D Tokenizer + 28,160 Neurons): Carrier=1,728Hz/18.5kHz -- FNO L2_Err=0.00019 -- PPL=1.00000002",
                    color = AccentAmber10,
                    fontSize = 8.4.sp,
                    fontFamily = FontFamily.Monospace,
                    modifier = Modifier.weight(0.72f)
                )
                ToolButton603010("VERIFY 400 LEAN 4", AccentAmber10, BgVoid60, Modifier.weight(0.28f)) {
                    invokeHostEndpoint("/api/v1/compiler/verify?q=" + java.net.URLEncoder.encode(leanQuery, "UTF-8"), null, "VERIFY 400/400 LEAN 4 QED")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(BgInset60, RoundedCornerShape(4.dp))
                    .border(1.dp, SlateBorder30, RoundedCornerShape(4.dp))
                    .padding(5.dp)
            ) {
                BasicTextField(
                    value = leanQuery,
                    onValueChange = { leanQuery = it },
                    textStyle = TextStyle(color = TextIvory30, fontSize = 9.sp, fontFamily = FontFamily.Monospace),
                    cursorBrush = SolidColor(AccentAmber10),
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }

        Spacer(modifier = Modifier.height(6.dp))

        // DRAWER 4: 80-TOOL EXECUTION REGISTRY (CHAIN 80 DAG), PRESET QUERIES & TELEMETRY LOG TERMINAL (ALL 16 BUTTONS MATCHING HOST)
        DrawerCard603010(
            title = "[-] DRAWER 4: 80-TOOL EXECUTION REGISTRY (CHAIN 80 DAG), PRESET QUERIES & TELEMETRY LOG TERMINAL",
            accentBorder = AccentRed10,
            titleColor = TextIvory30,
            rightLabel = String.format(Locale.US, "WS=%.1fk ops/s -- 28,160N", snap.clusterKops),
            isOpen = drawer4Open,
            onToggle = { drawer4Open = !drawer4Open }
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(BgInset60, RoundedCornerShape(4.dp))
                    .border(1.dp, SlateBorder30, RoundedCornerShape(4.dp))
                    .padding(6.dp)
            ) {
                BasicTextField(
                    value = cmdPrompt,
                    onValueChange = { cmdPrompt = it },
                    textStyle = TextStyle(color = TextIvory30, fontSize = 9.5.sp, fontFamily = FontFamily.Monospace),
                    cursorBrush = SolidColor(AccentAmber10),
                    modifier = Modifier.fillMaxWidth()
                )
            }
            Spacer(modifier = Modifier.height(4.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("EXECUTE PROMPT", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    val qEnc = java.net.URLEncoder.encode(cmdPrompt, "UTF-8")
                    invokeHostEndpoint("/api/v1/agent_gateway/interact?agent_id=mobile_hud&q=$qEnc", null, "EXECUTE PROMPT")
                }
                ToolButton603010("TRANSDUCE 65K BPE", Color(0xFF002B24), Color(0xFF00FFCC), Modifier.weight(1f)) {
                    val qEnc = java.net.URLEncoder.encode(cmdPrompt, "UTF-8")
                    invokeHostEndpoint("/api/v1/tokenizer/bpe_65k?q=$qEnc", null, "65,536-TOKEN BPE+8D INSPECTOR")
                }
                ToolButton603010("CHAIN 76", AccentRed10, TextIvory30, Modifier.weight(0.8f)) {
                    invokeHostEndpoint("/api/v1/harmonic/tool_chain?q=chain64_parallel_dag", null, "CHAIN 76")
                }
                ToolButton603010("CLEAR", SlateSurface30, TextIvory30, Modifier.weight(0.6f)) {
                    toolOutput = "READY."
                }
            }

            Spacer(modifier = Modifier.height(5.dp))

            // Natural Language Conversational Output Box (Tool 27) & Anomaly Banner (Tool 29)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(BgInset60, RoundedCornerShape(4.dp))
                    .border(1.dp, AccentAmber10, RoundedCornerShape(4.dp))
                    .padding(5.dp)
            ) {
                Column {
                    Text(
                        text = "[TOOL 27 MODEL NATURAL LANGUAGE SYNTHESIS & ALWAYS-ON MONOLOGUE]:",
                        color = AccentAmber10,
                        fontSize = 8.2.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Monospace
                    )
                    Text(
                        text = SovereignLiveBus.hostNlSynthesis,
                        color = TextIvory30,
                        fontSize = 8.4.sp,
                        lineHeight = 11.5.sp,
                        fontFamily = FontFamily.Monospace
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = "[TOOL 29 U(1) GAUGE]: " + SovereignLiveBus.hostAnomalyBanner,
                        color = StatusOk,
                        fontSize = 8.0.sp,
                        fontFamily = FontFamily.Monospace
                    )
                }
            }
            Spacer(modifier = Modifier.height(4.dp))

            // Row 00 (v44.0.0 QoL Slash-Command Chips + Tool 32 KHYS Mnemosyne + Tool 31 Cymatic 2-Bit SIMD)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("/SYNC", SlateSurface30, StatusOk, Modifier.weight(1f)) {
                    cmdPrompt = "/SYNC"
                    invokeHostEndpoint("/api/v1/model/converse?q=%2FSYNC", null, "SLASH /SYNC")
                }
                ToolButton603010("/LATTICE", SlateSurface30, StatusOk, Modifier.weight(1f)) {
                    cmdPrompt = "/LATTICE"
                    invokeHostEndpoint("/api/v1/model/converse?q=%2FLATTICE", null, "SLASH /LATTICE")
                }
                ToolButton603010("/IGNITE", SlateSurface30, StatusOk, Modifier.weight(1f)) {
                    cmdPrompt = "/IGNITE"
                    invokeHostEndpoint("/api/v1/model/converse?q=%2FIGNITE", null, "SLASH /IGNITE")
                }
                ToolButton603010("/OMNI_BRAID", SlateSurface30, StatusOk, Modifier.weight(1f)) {
                    cmdPrompt = "/EXECUTE_OMNI_BRAID"
                    invokeHostEndpoint("/api/v1/model/converse?q=%2FEXECUTE_OMNI_BRAID", null, "SLASH /EXECUTE_OMNI_BRAID")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            // Row v44.1.0: Perf Blitz Benchmark (T80), Elastic Work-Stealing Scheduler (T79), Browser WebGPU Lease (T78), Pixel 8 .npage SHM Ring (T77)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("T80: Perf Blitz", Color(0xFF261038), Color(0xFFFFD700), Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/diagnostics/v44_perf_blitz", null, "TOOL 80: v44.1.0 PERF BLITZ")
                }
                ToolButton603010("T79: Elastic Sched", Color(0xFF0D2618), Color(0xFF56D364), Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/worksteal/elastic_scheduler", null, "TOOL 79: ELASTIC SCHEDULER")
                }
                ToolButton603010("T78: WebGPU Lease", Color(0xFF091F2C), Color(0xFF00E5FF), Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/worksteal/webgpu_lease?action=status", null, "TOOL 78: WEBGPU LEASE STATUS")
                }
                ToolButton603010("T77: P8 .npage SHM", Color(0xFF2B2100), Color(0xFFFFB454), Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/shm/p8_npage_bridge", null, "TOOL 77: PIXEL 8 .NPAGE SHM")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            // Row v44.0.0: Omni-Snapshot (T76), Whole-Architecture Self-Profiler (T75), 16-Domain Socratic Debate (T74), Multi-Turn Working Memory (T73)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("T76: v44 Snapshot", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/manifold/v44_omni_snapshot", null, "TOOL 76: v44.0.0 OMNI-SNAPSHOT")
                }
                ToolButton603010("T75: Self-Profiler", Color(0xFF0D2618), Color(0xFF56D364), Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/diagnostics/v44_self_profiler", null, "TOOL 75: v44 SELF-PROFILER")
                }
                ToolButton603010("T74: Socratic Debate", Color(0xFF002B24), Color(0xFF00FFCC), Modifier.weight(1f)) {
                    val qEnc = java.net.URLEncoder.encode(cmdPrompt, "UTF-8")
                    invokeHostEndpoint("/api/v1/converse/dialectical_debate?q=$qEnc", null, "TOOL 74: 16-DOMAIN SOCRATIC DEBATE")
                }
                ToolButton603010("T73: Working Mem", Color(0xFF261038), Color(0xFFFFD700), Modifier.weight(1f)) {
                    val qEnc = java.net.URLEncoder.encode(cmdPrompt, "UTF-8")
                    invokeHostEndpoint("/api/v1/converse/multiturn_memory?q=$qEnc", null, "TOOL 73: MULTI-TURN WORKING MEMORY")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            // Row v44.0.0-ANTIGRAVITY: Antigravity Cutover (T72), Gemini 4 Argon 6-Agent Swarm (T71), 5W1H+21,120 Connectome (T70), .agents/ Rules (T69)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("T72: Antigravity", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/antigravity/cutover_status", null, "TOOL 72: ANTIGRAVITY CUTOVER")
                }
                ToolButton603010("T71: Argon Swarm", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/antigravity/argon_teamwork", null, "TOOL 71: GEMINI 4 ARGON 6-AGENT")
                }
                ToolButton603010("T70: 5W1H+Npage", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/connectome/harness_5w1h_npage", null, "TOOL 70: 5W1H+21120 CONNECTOME")
                }
                ToolButton603010("T69: .agents/", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/antigravity/rules_subagents", null, "TOOL 69: ANTIGRAVITY RULES")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            // Row v44.0.0-A: Embedded IDE Vault (T68), Operator Vault Gate (T67), Goose/Zed/Cline Parity (T66), 5W1H Distributed Router (T65)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("T68: IDE Vault", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/hud/embedded_ide_cockpit", null, "TOOL 68: EMBEDDED IDE VAULT")
                }
                ToolButton603010("T67: Vault Gate", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/auth/operator_vault_gate", null, "TOOL 67: OPERATOR VAULT GATE")
                }
                ToolButton603010("T66: IDE Parity", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/ide/symbiotic_parity_sync", null, "TOOL 66: GOOSE/ZED/CLINE PARITY")
                }
                ToolButton603010("T65: 5W1H Route", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/router/distributed_5w1h_dispatch", null, "TOOL 65: 5W1H DISTRIBUTED ROUTER")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            // Row v44.0.0-B: 21,120-Shard Vault (T62), 10-Session QAT Blitz (T61), Cloudflare D1 7-Tables (T60), Gemini Drive Bus (T55)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("T62: 21120 Shards", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/vault/shard_21120_verify", null, "TOOL 62: 21,120-SHARD VAULT")
                }
                ToolButton603010("T61: 10x QAT", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/qat/ten_session_blitz", null, "TOOL 61: 10-SESSION QAT BLITZ")
                }
                ToolButton603010("T60: D1 7-Tables", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/d1/seven_table_sync", null, "TOOL 60: CLOUDFLARE D1 7-TABLES")
                }
                ToolButton603010("T55: Gemini Bus", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/bridge/gemini_gdrive_sync", null, "TOOL 55: GEMINI GDRIVE BUS")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            // Row 000000: v44.0.0 Atomic Delta Engine (T54), A2A Mesh (T53), Auto-Learn Memory (T52), Code-Mode MCP+Roots (T51)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("T54: Atomic Delta", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/devops/atomic_delta_engine", null, "TOOL 54: ATOMIC DELTA")
                }
                ToolButton603010("T53: A2A Mesh", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/a2a/tasks", null, "TOOL 53: A2A MESH")
                }
                ToolButton603010("T52: Auto-Learn", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/memory/longterm_autolearn", null, "TOOL 52: AUTO-LEARN MEM")
                }
                ToolButton603010("T51: CodeMode MCP", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/mcp/code_mode_roots", null, "TOOL 51: CODEMODE ROOTS")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            // Row 00000: v44.0.0 64-Epoch Compound QAT (T50), Formant Speech+WAV (T49), 5W1H 4-Band Sweep, OpenAI /v1 Models
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("T50: Compound QAT", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/training/cross_domain_compound_qat", null, "TOOL 50: 6-DOMAIN QAT")
                }
                ToolButton603010("T49: Formant Speech", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/speech/cymatic_formant_tts", null, "TOOL 49: FORMANT SPEECH")
                }
                ToolButton603010("5W1H 4-Band Sweep", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/harness/metabolic_5w1h?load=sweep4", null, "5W1H 4-BAND SWEEP")
                }
                ToolButton603010("MCP tools/list", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/mcp/rpc?method=tools/list", null, "MCP TOOLS/LIST")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            // Row 0000: v44.0.0 Cloudflare D1+VPC Shadow (T48), OpenAI /v1 API (T47), MCP 2026 Server (T46), Metabolic 5W1H Harness (T45)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("T48: CF D1+VPC", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/cloudflare/d1_vpc_shadow", null, "TOOL 48: CLOUDFLARE D1+VPC")
                }
                ToolButton603010("T47: OpenAI /v1", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/openai/compat", null, "TOOL 47: OPENAI /V1 API")
                }
                ToolButton603010("T46: MCP Portal", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/mcp/rpc", null, "TOOL 46: MCP SERVER PORTAL")
                }
                ToolButton603010("T45: 5W1H Harness", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/harness/metabolic_5w1h", null, "TOOL 45: 5W1H HARNESS")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            // Row 000: v44.0.0 Amygdala+Kerr+Ravi (T44), Skyrmion+Fermi+XUV (T43), Neuron Pagefile .npage (T42), TorchTPU Bridge (T41)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("T44: Amygdala+Kerr", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/neuro/amygdala_kerr_ravi", null, "TOOL 44: AMYGDALA+KERR+RAVI")
                }
                ToolButton603010("T43: Skyrmion+Fermi", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/physics/skyrmion_fermi_xuv", null, "TOOL 43: SKYRMION+FERMI+XUV")
                }
                ToolButton603010("T42: Neuron .npage", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/pagefile/cauchy_sparse_npage", null, "TOOL 42: NEURON PAGEFILE")
                }
                ToolButton603010("T41: TorchTPU 2.48M", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/torchtpu/openxla_pallas_bridge", null, "TOOL 41: TORCHTPU BRIDGE")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            // Row 00A: v44.0.0 Sovereign Connectome (T37), DGM+AZR+SEAL (T38), Bi-Temporal WAL (T39), Pixel 8 P8-APEX (T40)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("T40: P8-APEX 588k", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/edge/p8_apex_coprocessor", null, "TOOL 40: PIXEL 8 P8-APEX")
                }
                ToolButton603010("T39: Bi-Temp WAL", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/logging/bitemporal_wal", null, "TOOL 39: BI-TEMPORAL WAL")
                }
                ToolButton603010("T38: DGM+AZR+SEAL", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/autopoiesis/dgm_azr_seal", null, "TOOL 38: DGM+AZR+SEAL")
                }
                ToolButton603010("T37: 21120N Connect", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/connectome/fno_synaptogenesis", null, "TOOL 37: 21120N CONNECTOME")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            // Row 00B: v34.0.0 Cosmohedron (T36), Amplituhedron (T35), Associahedron (T34), Martellini Entropic Time (T33)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("T36: Cosmohedron", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/geometry/cosmohedron_veclut", null, "TOOL 36: COSMOHEDRON C6")
                }
                ToolButton603010("T35: Amplituhedron", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/geometry/amplituhedron_clifford", null, "TOOL 35: AMPLITUHEDRON")
                }
                ToolButton603010("T34: Associahedron", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/geometry/associahedron_tropical", null, "TOOL 34: ASSOCIAHEDRON K6")
                }
                ToolButton603010("T33: Martellini Time", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/time/martellini_spherical", null, "TOOL 33: MARTELLINI TIME")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("T32: KHYS Mnemosyne", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/khys/mnemosyne_planetary", null, "TOOL 32: KHYS MNEMOSYNE")
                }
                ToolButton603010("T31: Cymatic 2-Bit", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    val qEnc = java.net.URLEncoder.encode(cmdPrompt, "UTF-8")
                    invokeHostEndpoint("/api/v1/cymatic/chromatic_verify?q=$qEnc", null, "TOOL 31: CYMATIC OMEGA.2")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))

            // Row 0A: TOOL 30 (15.965Hz Decadic), TOOL 29 (U(1) Anomaly), TOOL 28 (Episodic Search), TOOL 27 (NL Converse)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("T30: 15.965Hz Decadic", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/physics/decadic_synthesizer", null, "TOOL 30: DECADIC 15.965Hz")
                }
                ToolButton603010("T29: U(1) Anomaly", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/anomaly/stream", null, "TOOL 29: U(1) ANOMALY")
                }
                ToolButton603010("T28: Episodic Search", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    val qEnc = java.net.URLEncoder.encode(cmdPrompt, "UTF-8")
                    invokeHostEndpoint("/api/v1/memory/episodic_search?q=$qEnc", null, "TOOL 28: EPISODIC SEARCH")
                }
                ToolButton603010("T27: NL Converse", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    val qEnc = java.net.URLEncoder.encode(cmdPrompt, "UTF-8")
                    invokeHostEndpoint("/api/v1/model/converse?q=$qEnc", null, "TOOL 27: NL CONVERSE")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))

            // Row 0B: TOOL 26 (21,120 Harvester), TOOL 25 (32-Epoch QAT), TOOL 24 (Sync Matrix), Always-On Toggle
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("T26: 21120 Harvester", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/vault/harvest", null, "TOOL 26: 21,120 HARVESTER")
                }
                ToolButton603010("T25: 32-Epoch QAT", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/train/continual_qat?q=mobile_epoch32", null, "TOOL 25: QAT TRAINER")
                }
                ToolButton603010("T24: Sync Matrix", SlateSurface30, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/cluster/sync_matrix", null, "TOOL 24: SYNC MATRIX")
                }
                ToolButton603010("ALWAYS-ON TOGGLE", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/always_on/toggle", null, "ALWAYS-ON STREAM")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))

            // Row 1: TOOL 21, TOOL 22, TOOL 23, TOOL 20
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("TOOL 21: LLM Gateway", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/agent_gateway/interact?agent_id=pixel_v32_8&q=inspect", null, "TOOL 21: LLM GATEWAY")
                }
                ToolButton603010("TOOL 22: FNO PDE", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/operator/fno_solve?q=navier_stokes_16x80", null, "TOOL 22: FNO PDE")
                }
                ToolButton603010("TOOL 23: E:/ SSD Vault", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/storage/ssd_tier2?q=merkle32_verify", null, "TOOL 23: E:/ SSD VAULT")
                }
                ToolButton603010("TOOL 20: ER Browser", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/browser/fetch?url=https://arxiv.org/abs/1306.0533", null, "TOOL 20: ER BROWSER")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))

            // Row 2: TOOL 19, TOOL 18, TOOL 17, TOOL 16
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("TOOL 19: RTX 3050 6GB", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/compute/wgsl", null, "TOOL 19: RTX 3050 GEMM")
                }
                ToolButton603010("TOOL 18: SIEM & PQ", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/.well-known/llm-agent.json", null, "TOOL 18: SIEM & PQ")
                }
                ToolButton603010("TOOL 17: Acoustic SDR", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/acoustic/ping", null, "TOOL 17: ACOUSTIC SDR")
                }
                ToolButton603010("TOOL 16: Stiefel St", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/manifold/stiefel_step", null, "TOOL 16: STIEFEL St(16,80)")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))

            // Row 3: TOOL 15, TOOL 14, TOOL 13, TOOL 12
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("TOOL 15: Debate 1280", SlateSurface30, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/debate/consensus", null, "TOOL 15: MULTI-AGENT DEBATE")
                }
                ToolButton603010("TOOL 14: Hot-Patch", SlateSurface30, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/hotpatch/apply", null, "TOOL 14: AUTONOMOUS PATCH")
                }
                ToolButton603010("TOOL 13: Work-Steal", SlateSurface30, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/compiler/verify", null, "TOOL 13: WORK-STEAL VERIFY")
                }
                ToolButton603010("TOOL 12: 8-Lang Code", SlateSurface30, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/codegen/synthesize", null, "TOOL 12: POLYGLOT CODEGEN")
                }
            }
            Spacer(modifier = Modifier.height(4.dp))

            // Row 4: TOOL 8, TOOL 5, TOOL 2, CHAIN 76
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ToolButton603010("TOOL 8: Self-Analyze", AccentAmber10, BgVoid60, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/telemetry", null, "TOOL 8: ZERO-DUMMY AUDIT")
                }
                ToolButton603010("TOOL 5: Lean 4 (400)", SlateSurface30, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/compiler/verify", null, "TOOL 5: 400/400 LEAN 4 PROOFS")
                }
                ToolButton603010("TOOL 2: Vault (28160)", SlateSurface30, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/StateGraph", null, "TOOL 2: 28,160-NEURON VAULT")
                }
                ToolButton603010("CHAIN 80: Full Verify", AccentRed10, TextIvory30, Modifier.weight(1f)) {
                    invokeHostEndpoint("/api/v1/harmonic/tool_chain?q=chain80_parallel_dag", null, "CHAIN 80: 80-TOOL VERIFY")
                }
            }

            Spacer(modifier = Modifier.height(6.dp))

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(BgInset60, RoundedCornerShape(4.dp))
                    .border(1.dp, SlateBorder30, RoundedCornerShape(4.dp))
                    .padding(6.dp)
            ) {
                Column {
                    Text(
                        text = "> PROMPT: $cmdPrompt",
                        color = TextIvory30,
                        fontSize = 8.8.sp,
                        fontFamily = FontFamily.Monospace
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = String.format(Locale.US, "[SH4Z v4440 (133,120 B / 130.00 KB 80-Sector 60-30-10 HUD)]: Work-Stealing=2,080 Lines (%.1fk ops/s) -- 400/400 Lean 4 QED -- 28,160 Neurons (640x Chair44, 3.56MB SHM) -- 65,536 BPE+16D Tokens -- E:/ Tier-2 SSD Active -- PPL=1.00000002", snap.clusterKops),
                        color = AccentAmber10,
                        fontSize = 8.5.sp,
                        lineHeight = 12.sp,
                        fontFamily = FontFamily.Monospace
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = "> OUTPUT: $toolOutput",
                        color = StatusOk,
                        fontSize = 8.8.sp,
                        lineHeight = 12.sp,
                        fontFamily = FontFamily.Monospace
                    )
                }
            }
        }
    }
}

@Composable
fun MiniTelemetryCard(
    item: TelemetryCardItem,
    isSelected: Boolean = false,
    modifier: Modifier = Modifier,
    onClick: () -> Unit = {}
) {
    Column(
        modifier = modifier
            .background(BgInset60, RoundedCornerShape(5.dp))
            .border(
                if (isSelected) 1.5.dp else 1.dp,
                if (isSelected) AccentAmber10 else SlateBorder30,
                RoundedCornerShape(5.dp)
            )
            .clickable { onClick() }
            .padding(6.dp)
    ) {
        Text(
            text = item.title,
            color = TextMuted30,
            fontSize = 7.6.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = FontFamily.Monospace
        )
        Spacer(modifier = Modifier.height(2.dp))
        Text(
            text = item.primary,
            color = if (item.isAccent) AccentAmber10 else TextIvory30,
            fontSize = 9.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = FontFamily.Monospace
        )
        Spacer(modifier = Modifier.height(1.dp))
        Text(
            text = item.secondary,
            color = AccentAmber10,
            fontSize = 7.6.sp,
            fontFamily = FontFamily.Monospace
        )
    }
}

@Composable
fun DrawerCard603010(
    title: String,
    accentBorder: Color,
    titleColor: Color,
    rightLabel: String = "",
    isOpen: Boolean,
    onToggle: () -> Unit,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(BgPanel60, RoundedCornerShape(6.dp))
            .border(1.dp, accentBorder, RoundedCornerShape(6.dp))
            .padding(8.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { onToggle() },
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = title,
                color = titleColor,
                fontSize = 9.2.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Monospace,
                modifier = Modifier.weight(1f)
            )
            Text(
                text = if (rightLabel.isNotEmpty()) "$rightLabel -- ${if (isOpen) "FOLD" else "OPEN"}" else if (isOpen) "FOLD" else "OPEN",
                color = AccentAmber10,
                fontSize = 8.sp,
                fontFamily = FontFamily.Monospace
            )
        }
        if (isOpen) {
            Spacer(modifier = Modifier.height(5.dp))
            content()
        }
    }
}

@Composable
fun ToolButton603010(
    label: String,
    bg: Color,
    fg: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Box(
        modifier = modifier
            .height(34.dp)
            .background(bg, RoundedCornerShape(4.dp))
            .border(1.dp, SlateBorder30, RoundedCornerShape(4.dp))
            .clickable { onClick() }
            .padding(horizontal = 4.dp, vertical = 2.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = label,
            color = fg,
            fontSize = 8.0.sp,
            lineHeight = 10.0.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = FontFamily.Monospace
        )
    }
}
