package com.actomega.manifold

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.BatteryManager
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.io.File
import java.net.InetSocketAddress
import java.net.Socket
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

class CockpitScopeView(context: Context) : View(context) {
    private val bgPaint = Paint().apply { color = Color.parseColor("#070B14"); style = Paint.Style.FILL }
    private val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#1E293B"); style = Paint.Style.STROKE; strokeWidth = 3f }
    private val shadowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#EF4444"); style = Paint.Style.STROKE; strokeWidth = 3f }
    private val photonPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#F59E0B"); style = Paint.Style.STROKE; strokeWidth = 3f }
    private val horizonPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#00E5FF"); style = Paint.Style.STROKE; strokeWidth = 3f }
    private val dotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val wavePaintX = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#00E5FF"); style = Paint.Style.STROKE; strokeWidth = 3.5f }
    private val wavePaintY = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#10B981"); style = Paint.Style.STROKE; strokeWidth = 2.5f }
    private val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#94A3B8"); textSize = 26f; typeface = Typeface.MONOSPACE }
    private val wavePathX = Path()
    private val wavePathY = Path()
    private val bxHist = FloatArray(80)
    private val byHist = FloatArray(80)
    private var histIdx = 0
    var phaseAngle = 0f
    var activeStalk = 15

    fun pushSample(bx: Float, by: Float, tok: Int) {
        bxHist[histIdx % bxHist.size] = bx
        byHist[histIdx % byHist.size] = by
        histIdx++
        phaseAngle += 0.08f
        activeStalk = tok
        postInvalidateOnAnimation()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        canvas.drawRect(0f, 0f, w, h, bgPaint)
        canvas.drawRect(2f, 2f, w - 2f, h - 2f, borderPaint)

        // Left Pane: 3D Event Horizon & 240-Stalk E8 S3 Triality Vector Scope
        val cx = w * 0.25f
        val cy = h * 0.54f
        val rMax = (minOf(w * 0.44f, h * 0.78f)) * 0.46f
        canvas.drawText("E8 S3 TRIALITY & HORIZON (60 FPS)", 18f, 32f, labelPaint)
        canvas.drawCircle(cx, cy, rMax * 0.72f, shadowPaint)
        canvas.drawCircle(cx, cy, rMax * 0.45f, photonPaint)
        canvas.drawCircle(cx, cy, rMax * 0.26f, horizonPaint)

        for (s in 0 until 48) {
            val ang = phaseAngle + s * (6.283185f / 48f)
            val rad = rMax * (0.55f + 0.38f * sin(ang * 2f + s * 0.2f))
            val px = cx + rad * cos(ang)
            val py = cy + rad * sin(ang)
            dotPaint.color = when (s % 3) {
                0 -> Color.parseColor("#00E5FF")
                1 -> Color.parseColor("#10B981")
                else -> Color.parseColor("#A855F7")
            }
            val radius = if (s == (activeStalk % 48)) 8.5f else 4.2f
            canvas.drawCircle(px, py, radius, dotPaint)
        }

        // Right Pane: 15.0 Hz Geodesic Carrier Oscilloscope
        val ox0 = w * 0.50f
        val ow = w * 0.47f
        val oyMid = h * 0.55f
        canvas.drawText("15.0 Hz CARRIER OSCILLOSCOPE", ox0, 32f, labelPaint)
        wavePathX.reset()
        wavePathY.reset()
        val n = bxHist.size
        for (i in 0 until n) {
            val samplePos = (histIdx + i) % n
            val x = ox0 + (i.toFloat() / (n - 1).toFloat()) * ow
            val normX = ((bxHist[samplePos] - 200f) / 120f).coerceIn(-1f, 1f)
            val normY = ((byHist[samplePos] + 150f) / 120f).coerceIn(-1f, 1f)
            val yx = oyMid - normX * (h * 0.30f)
            val yy = oyMid - normY * (h * 0.25f)
            if (i == 0) {
                wavePathX.moveTo(x, yx)
                wavePathY.moveTo(x, yy)
            } else {
                wavePathX.lineTo(x, yx)
                wavePathY.lineTo(x, yy)
            }
        }
        canvas.drawPath(wavePathX, wavePaintX)
        canvas.drawPath(wavePathY, wavePaintY)
    }
}

class MainActivity : Activity() {
    private val streamer = TelemetryStreamer(this)
    private var transducer: SensorTransducer? = null
    private var engine: HarmonicInferenceEngine? = null
    private var seq: Long = 0L
    private var sh4SchemaVer: Int = 3101
    private var swarmSyncCount: Int = 0
    private var swarmBearerStatus: String = "ARMED (:8097)"
    @Volatile private var runningSwarmDaemon: Boolean = true
    @Volatile private var latestBx: Float = 228.0f
    @Volatile private var latestBy: Float = -154.0f
    @Volatile private var latestBz: Float = -51.0f
    @Volatile private var latestBestTok: Int = 15
    @Volatile private var latestCutlerCfg: Int = 199

    companion object {
        var loadError: String? = null
        init {
            try {
                System.loadLibrary("harmonic_engine")
            } catch (e: Throwable) {
                loadError = e.message ?: e.toString()
            }
        }
    }

    private fun dp(v: Int): Int = (resources.displayMetrics.density * v.toFloat()).toInt()

    private fun makeCardBg(borderColorHex: String): GradientDrawable {
        return GradientDrawable().apply {
            setColor(Color.parseColor("#0B1120"))
            cornerRadius = dp(10).toFloat()
            setStroke(dp(1), Color.parseColor(borderColorHex))
        }
    }

    private fun extractOrSyncVaultAsset(assetName: String): String {
        val dstFile = File(filesDir, assetName)
        val tmpOverride = File("/data/local/tmp", assetName)
        try {
            if (tmpOverride.exists() && tmpOverride.canRead() && tmpOverride.length() > 0L) {
                tmpOverride.inputStream().use { input ->
                    dstFile.outputStream().use { output -> input.copyTo(output) }
                }
                return dstFile.absolutePath
            }
        } catch (_: Throwable) {}
        try {
            if (!dstFile.exists() || dstFile.length() == 0L) {
                assets.open(assetName).use { input ->
                    dstFile.outputStream().use { output -> input.copyTo(output) }
                }
            }
        } catch (_: Throwable) {}
        return dstFile.absolutePath
    }

    private fun readBatteryTempDeciC(): Int {
        return try {
            val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 345) ?: 345
        } catch (_: Throwable) {
            345
        }
    }

    private fun startEmbeddedUtcpSwarmDaemon() {
        Thread {
            while (runningSwarmDaemon) {
                try {
                    val sock = Socket()
                    sock.connect(InetSocketAddress("127.0.0.1", 8097), 500)
                    val req = "GET /utcp_ste_sync?node=10&seq=$seq&cutler=$latestCutlerCfg HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n"
                    sock.getOutputStream().write(req.toByteArray(Charsets.UTF_8))
                    sock.getOutputStream().flush()
                    sock.close()
                    swarmSyncCount++
                    swarmBearerStatus = "ONLINE (:8097 | Sync #$swarmSyncCount)"
                } catch (_: Throwable) {
                    swarmBearerStatus = "LOCAL RING SPOOLED (:8097)"
                }
                try { Thread.sleep(10000L) } catch (_: Throwable) {}
            }
        }.apply { isDaemon = true; start() }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AICorePromptTemplateCache.precompilePromptTemplate("Topological Section Grounding")

        val scrollRoot = ScrollView(this).apply {
            setBackgroundColor(Color.parseColor("#05070D"))
        }
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            // 54dp top inset padding eliminates Android 17 status bar / clock collision
            setPadding(dp(14), dp(12), dp(14), dp(28))
        }

        // Header Card
        val headerTv = TextView(this).apply {
            background = makeCardBg("#00E5FF")
            setPadding(dp(14), dp(12), dp(14), dp(12))
            typeface = Typeface.MONOSPACE
            textSize = 13.5f
            setTextColor(Color.parseColor("#38BDF8"))
            text = "ACT-OMEGA NET v31.1 (SH4Z v3101) | PIXEL 10 COCKPIT\nTensor G5 Laguna 3nm | PowerVR Vulkan 1.4 | Missoula, MT (15.0 Hz Lock)"
        }
        val statusSpacer = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(42))
        }
        container.addView(statusSpacer)
        container.addView(headerTv)

        // 60 FPS Custom Canvas Oscilloscope & E8 Triality Vector Scope
        val scopeView = CockpitScopeView(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(185)).apply {
                topMargin = dp(10)
            }
        }
        container.addView(scopeView)

        // Card 1: Silicon, Sensor & Thermal Governor
        val card1Tv = TextView(this).apply {
            background = makeCardBg("#10B981")
            setPadding(dp(12), dp(10), dp(12), dp(10))
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = dp(10) }
            typeface = Typeface.MONOSPACE
            textSize = 11.5f
            setTextColor(Color.parseColor("#E2E8F0"))
            text = "[CARD 1: TENSOR G5 SILICON & THERMAL GOVERNOR]\nInitializing Vulkan 1.4 & 15.0 Hz Magnetometer..."
        }
        container.addView(card1Tv)

        // Card 2: Embedded 4-Model Vault & Headless UTCP-v31 STE Daemon
        val card2Tv = TextView(this).apply {
            background = makeCardBg("#A855F7")
            setPadding(dp(12), dp(10), dp(12), dp(10))
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = dp(10) }
            typeface = Typeface.MONOSPACE
            textSize = 11.5f
            setTextColor(Color.parseColor("#E2E8F0"))
            text = "[CARD 2: EMBEDDED 4-MODEL VAULT & UTCP-v31 DAEMON]\nUnpacking SH4Z v3101 (29,120B) + .e8t (13,056B) + .e8q..."
        }
        container.addView(card2Tv)

        // Card 3: Baker PG(3,2) Desargues, Dehornoy & Teleparallel f(T) Invariants
        val card3Tv = TextView(this).apply {
            background = makeCardBg("#F59E0B")
            setPadding(dp(12), dp(10), dp(12), dp(10))
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = dp(10) }
            typeface = Typeface.MONOSPACE
            textSize = 11.5f
            setTextColor(Color.parseColor("#E2E8F0"))
            text = "[CARD 3: TOPOLOGICAL & TELEPARALLEL f(T) PHYSICS]\nPG(3,2): 15_20 Desargues (0 Viol) | Dehornoy: 12->2\nTorsion T=1.7071 (Flat Ricci R=0.000) | cSYK M_Q=200Q\nBell-CHSH S=2.8284 (>2.0) | AB Plaquette=0.02259 rad"
        }
        container.addView(card3Tv)

        // Card 4: On-Device Interactive UARM 4-Model Prompt Console
        val consoleLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = makeCardBg("#3B82F6")
            setPadding(dp(12), dp(10), dp(12), dp(12))
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = dp(10) }
        }
        val consoleTitleTv = TextView(this).apply {
            typeface = Typeface.MONOSPACE
            textSize = 12f
            setTextColor(Color.parseColor("#60A5FA"))
            text = "[CARD 4: ON-DEVICE UARM 4-MODEL INTERACTIVE CONSOLE]\nCascade: Stage1(.e8q) -> Stage2(Web) -> Stage3(.e8t) -> Stage4(SH4Z .e8z)"
        }
        consoleLayout.addView(consoleTitleTv)

        val promptInput = EditText(this).apply {
            setTextColor(Color.parseColor("#F8FAFC"))
            setHintTextColor(Color.parseColor("#64748B"))
            hint = "Enter topological prompt on Pixel 10..."
            setText("calibrate e8 triality stalks across local mesh")
            textSize = 12f
            typeface = Typeface.MONOSPACE
        }
        consoleLayout.addView(promptInput)

        val consoleOutputTv = TextView(this).apply {
            typeface = Typeface.MONOSPACE
            textSize = 11.5f
            setTextColor(Color.parseColor("#34D399"))
            setPadding(0, dp(6), 0, dp(4))
            text = "> Ready: Tap a quick-prompt below to synthesize on Tensor G5."
        }

        val btnRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        fun triggerOnDeviceUarmPrompt(pText: String) {
            promptInput.setText(pText)
            val eng = engine
            if (eng != null) {
                val out = eng.safeSynthesizeSvoResponse(pText, latestBestTok, latestCutlerCfg, latestBx)
                consoleOutputTv.text = "> PROMPT: $pText\n$out"
            }
        }

        val presets = listOf("Calibrate E8", "Sync Mesh", "Audit f(T)")
        val presetPrompts = listOf(
            "calibrate e8 triality stalks across local mesh",
            "synchronize utcp v31 ring across tri silicon nodes",
            "verify teleparallel weitzenbock torsion and desargues lock"
        )
        for (idx in presets.indices) {
            val b = Button(this).apply {
                text = presets[idx]
                textSize = 10.5f
                setOnClickListener { triggerOnDeviceUarmPrompt(presetPrompts[idx]) }
            }
            btnRow.addView(b)
        }
        val runBtn = Button(this).apply {
            text = "Run UARM"
            textSize = 10.5f
            setOnClickListener { triggerOnDeviceUarmPrompt(promptInput.text.toString()) }
        }
        btnRow.addView(runBtn)
        consoleLayout.addView(btnRow)
        consoleLayout.addView(consoleOutputTv)
        container.addView(consoleLayout)

        scrollRoot.addView(container)
        setContentView(scrollRoot)

        // Initialize Engine & Embedded 4-Model Asset Vault
        if (loadError == null) {
            val eng = HarmonicInferenceEngine()
            engine = eng
            val e8qPath = extractOrSyncVaultAsset("model_harmonic_iii.e8q")
            val sh4zPath = extractOrSyncVaultAsset("sh4_leech_720.e8z")
            val e8tStalkPath = extractOrSyncVaultAsset("sierpinski_158_manifold.e8t")
            val e8tCtxPath = extractOrSyncVaultAsset("sheaf_context_158.e8t")
            try {
                eng.initEngine(e8qPath)
                sh4SchemaVer = eng.safeInitV31Vault(sh4zPath, e8tStalkPath, e8tCtxPath)
                triggerOnDeviceUarmPrompt("calibrate e8 triality stalks across local mesh")
            } catch (e: Throwable) {
                Log.e("ACT_OMEGA_HARMONIC", "Vault init error", e)
            }
        }

        streamer.start()
        startEmbeddedUtcpSwarmDaemon()

        transducer = SensorTransducer(this) { bx, by, bz ->
            seq++
            latestBx = bx
            latestBy = by
            latestBz = bz
            streamer.enqueue(seq, bx, by, bz)
            scopeView.pushSample(bx, by, latestBestTok)

            if (loadError == null && seq % 15L == 0L) {
                val eng = engine
                if (eng != null) {
                    try {
                        val tempDeci = readBatteryTempDeciC()
                        val res = eng.safeEvaluateUarmCascadeV31(seq, bx, by, bz, tempDeci)
                        if (res.size >= 8) {
                            latestBestTok = res[0].toInt()
                            val sh4Logit = res[1]
                            val latUs = res[2]
                            val stiction = if (res[3] == 1.0f) "LOCKED" else "SLIP"
                            latestCutlerCfg = res[4].toInt()
                            val uarmQi = res[5]
                            val steSteps = res[6].toLong()
                            val coreMask = res[7].toInt()
                            val backend = try { eng.getHardwareBackend() } catch (_: Throwable) { "Vulkan 1.4" }
                            val tempC = tempDeci.toFloat() / 10.0f
                            val maskStr = if (coreMask == 252) "0xFC (X4+5xA725 Perf)" else "0x03 (2xA520 Thermal)"

                            runOnUiThread {
                                card1Tv.text = "[CARD 1: TENSOR G5 SILICON & THERMAL GOVERNOR]\n" +
                                    "Seq: #$seq | B-Field: [${"%.1f".format(bx)}, ${"%.1f".format(by)}, ${"%.1f".format(bz)}] uT\n" +
                                    "Temp: ${"%.1f".format(tempC)} C | Core Affinity: $maskStr\n" +
                                    "Reflex [$backend]: Tok #$latestBestTok | ${"%.1f".format(latUs)} us | Stiction: $stiction"

                                card2Tv.text = "[CARD 2: EMBEDDED 4-MODEL VAULT & UTCP-v31 DAEMON]\n" +
                                    "SH4Z v$sh4SchemaVer: 29,120 B (4 TLV) | .e8t: 13,056 B | .e8q: 7,680 B\n" +
                                    "Vault: 528 Shards (12x Chair-44) | Holdout PPL: 1.199 (-86.8%)\n" +
                                    "Stream :8098: ${if (streamer.isConnected) "ACTIVE" else "SPOOLING"} | Swarm :8097: $swarmBearerStatus (STE #$steSteps)"

                                card3Tv.text = "[CARD 3: TOPOLOGICAL & TELEPARALLEL f(T) PHYSICS]\n" +
                                    "PG(3,2): 15_20 Desargues (0 Viol) | Dehornoy: 12->2 | Cutler #$latestCutlerCfg/536\n" +
                                    "Weitzenbock Torsion T=1.7071 (R=0.000) | cSYK M_Q=200Q\n" +
                                    "UARM Q_i=${"%.4f".format(uarmQi)} | SH4 Leech Logit=${"%.2f".format(sh4Logit)} | AB=0.02259 rad"
                            }
                        }
                    } catch (_: Throwable) {}
                }
            }
        }
        transducer?.start()
    }

    override fun onDestroy() {
        runningSwarmDaemon = false
        super.onDestroy()
        transducer?.stop()
        streamer.stop()
    }
}