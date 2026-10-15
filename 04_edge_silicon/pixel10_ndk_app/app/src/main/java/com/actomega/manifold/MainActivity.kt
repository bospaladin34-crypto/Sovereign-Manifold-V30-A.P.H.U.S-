package com.actomega.manifold

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.BatteryManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.InetSocketAddress
import java.net.Socket
import java.net.URL
import java.util.Locale
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

class MultiSensorLeechCollector(private val ctx: Context) : SensorEventListener {
    private val sm = ctx.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    @Volatile var bx = 22.8f; @Volatile var by = -41.2f; @Volatile var bz = 12.8f
    @Volatile var baroHpa = 923.8f; @Volatile var lightLux = 94.0f; @Volatile var proxCm = 5.0f
    @Volatile var ax = 0.93f; @Volatile var ay = 3.47f; @Volatile var az = 8.50f
    @Volatile var gx = 0.05f; @Volatile var gy = 0.12f; @Volatile var gz = 0.18f
    @Volatile var tempDeciC = 329; @Volatile var voltageMv = 4265; @Volatile var currentMa = 1355
    @Volatile var batteryPct = 74; @Volatile var ramAvailMb = 1850; @Volatile var ramTotalMb = 11544
    @Volatile var lastVulkanUs = 28.0f; @Volatile var lastCutler = 294
    @Volatile var lastTorsionT = 1.73042f; @Volatile var lastBeaming = 27.32f; @Volatile var lastLogit = 1468.40f

    fun start() {
        val types = intArrayOf(
            Sensor.TYPE_MAGNETIC_FIELD, Sensor.TYPE_ACCELEROMETER, Sensor.TYPE_GYROSCOPE,
            Sensor.TYPE_PRESSURE, Sensor.TYPE_LIGHT, Sensor.TYPE_PROXIMITY
        )
        for (t in types) {
            sm.getDefaultSensor(t)?.let { s -> sm.registerListener(this, s, SensorManager.SENSOR_DELAY_GAME) }
        }
    }
    fun stop() { sm.unregisterListener(this) }

    override fun onSensorChanged(e: SensorEvent?) {
        val ev = e ?: return
        when (ev.sensor.type) {
            Sensor.TYPE_MAGNETIC_FIELD -> if (ev.values.size >= 3) { bx = ev.values[0]; by = ev.values[1]; bz = ev.values[2] }
            Sensor.TYPE_ACCELEROMETER -> if (ev.values.size >= 3) { ax = ev.values[0]; ay = ev.values[1]; az = ev.values[2] }
            Sensor.TYPE_GYROSCOPE -> if (ev.values.size >= 3) { gx = ev.values[0]; gy = ev.values[1]; gz = ev.values[2] }
            Sensor.TYPE_PRESSURE -> if (ev.values.isNotEmpty()) { baroHpa = ev.values[0] }
            Sensor.TYPE_LIGHT -> if (ev.values.isNotEmpty()) { lightLux = ev.values[0] }
            Sensor.TYPE_PROXIMITY -> if (ev.values.isNotEmpty()) { proxCm = ev.values[0] }
        }
    }
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    fun refreshSiliconTelemetry() {
        try {
            val bm = ctx.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            if (bm != null) {
                tempDeciC = bm.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 329)
                voltageMv = bm.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 4265)
                batteryPct = bm.getIntExtra(BatteryManager.EXTRA_LEVEL, 74)
            }
            val bMgr = ctx.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
            if (bMgr != null) {
                val rawCurr = bMgr.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
                currentMa = if (abs(rawCurr) > 1000) rawCurr / 1000 else rawCurr
            }
            val am = ctx.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            if (am != null) {
                val mi = ActivityManager.MemoryInfo()
                am.getMemoryInfo(mi)
                ramAvailMb = (mi.availMem / (1024L * 1024L)).toInt()
                ramTotalMb = (mi.totalMem / (1024L * 1024L)).toInt()
            }
        } catch (_: Throwable) {}
    }

    fun snapshot24D(reflexUs: Float): FloatArray {
        val bNorm = sqrt(bx * bx + by * by + bz * bz)
        val aNorm = sqrt(ax * ax + ay * ay + az * az)
        val gNorm = sqrt(gx * gx + gy * gy + gz * gz)
        val tempC = tempDeciC / 10.0f
        val powerW = (voltageMv.toFloat() * abs(currentMa).toFloat()) / 1_000_000.0f
        val mask = if (tempDeciC >= 390) 3.0f else 252.0f
        return floatArrayOf(
            bx, by, bz, bNorm, baroHpa, lightLux, proxCm, 0.17259f,
            ax, ay, az, gx, gy, gz, aNorm, gNorm,
            tempC, voltageMv.toFloat(), currentMa.toFloat(), powerW,
            batteryPct.toFloat(), ramAvailMb.toFloat(), mask, reflexUs
        )
    }
}

class Leech24DScopeView(ctx: Context) : View(ctx) {
    private val paintGrid = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#1E293B"); style = Paint.Style.STROKE; strokeWidth = 2f }
    private val paintCyan = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#38BDF8"); style = Paint.Style.STROKE; strokeWidth = 3f }
    private val paintGreen = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#34D399"); style = Paint.Style.STROKE; strokeWidth = 2.5f }
    private val paintAmber = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#F59E0B"); style = Paint.Style.STROKE; strokeWidth = 2.5f }
    private val paintLabel = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#94A3B8"); textSize = 24f; typeface = Typeface.MONOSPACE }
    private val histBx = FloatArray(64); private val histAz = FloatArray(64); private val histGw = FloatArray(64)
    private var head = 0; private var phase = 0f

    fun pushSample(bx: Float, az: Float, gw: Float) {
        histBx[head] = bx + sin(phase * 1.5f) * 1.8f
        histAz[head] = az + cos(phase * 1.2f) * 0.35f
        histGw[head] = gw + abs(sin(phase * 0.9f)) * 0.08f
        head = (head + 1) and 63
        phase += 0.11f
        postInvalidateOnAnimation()
    }

    private fun normSample(arr: FloatArray, v: Float): Float {
        var mn = arr[0]; var mx = arr[0]
        for (x in arr) { if (x < mn) mn = x; if (x > mx) mx = x }
        val span = (mx - mn).coerceAtLeast(0.5f)
        return (((v - mn) / span) * 2f - 1f).coerceIn(-1f, 1f)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat(); val h = height.toFloat()
        canvas.drawColor(Color.parseColor("#070D19"))
        val midX = w * 0.42f; val cx = midX * 0.5f; val cy = h * 0.54f; val rOuter = minOf(cx, cy) * 0.72f
        canvas.drawCircle(cx, cy, rOuter, paintGrid); canvas.drawCircle(cx, cy, rOuter * 0.55f, paintGrid)
        for (k in 0 until 24) {
            val ang = phase + k * (6.283185f / 24f)
            val rad = rOuter * (0.45f + 0.45f * sin(phase * 0.7f + k))
            val px = cx + rad * cos(ang); val py = cy + rad * sin(ang)
            val p = when (k % 3) { 0 -> paintCyan; 1 -> paintGreen; else -> paintAmber }
            canvas.drawLine(cx, cy, px, py, p)
        }
        canvas.drawText("LEECH 24D HORIZON", 18f, 32f, paintLabel)
        val ox0 = midX + 12f; val ow = w - ox0 - 16f
        canvas.drawRect(ox0, 14f, w - 14f, h - 14f, paintGrid)
        canvas.drawText("8v(B) + 8+(A/W) OSCILLOSCOPE", ox0 + 12f, 36f, paintLabel)
        val pathB = Path(); val pathA = Path(); val pathG = Path()
        for (i in 0 until 64) {
            val idx = (head + i) and 63
            val x = ox0 + (i.toFloat() / 63f) * ow
            val yb = (h * 0.36f) - normSample(histBx, histBx[idx]) * (h * 0.14f)
            val ya = (h * 0.58f) - normSample(histAz, histAz[idx]) * (h * 0.14f)
            val yg = (h * 0.78f) - normSample(histGw, histGw[idx]) * (h * 0.14f)
            if (i == 0) { pathB.moveTo(x, yb); pathA.moveTo(x, ya); pathG.moveTo(x, yg) }
            else { pathB.lineTo(x, yb); pathA.lineTo(x, ya); pathG.lineTo(x, yg) }
        }
        canvas.drawPath(pathB, paintCyan); canvas.drawPath(pathA, paintGreen); canvas.drawPath(pathG, paintAmber)
    }
}

class MainActivity : Activity() {
    private val engine = HarmonicInferenceEngine()
    private var collector: MultiSensorLeechCollector? = null
    private val uiHandler = Handler(Looper.getMainLooper())
    @Volatile private var running = false
    @Volatile private var swarmStatus = "STARTING..."
    @Volatile private var steStep = 832L
    private var seqCounter = 5100L

    private fun dp(v: Int): Int =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics).toInt()

    private fun cardBg(borderHex: String): GradientDrawable = GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE; cornerRadius = dp(10).toFloat()
        setColor(Color.parseColor("#111A2E")); setStroke(dp(1), Color.parseColor(borderHex))
    }

    private fun unpackAssetIfNeeded(fileName: String): File {
        val outFile = File(filesDir, fileName)
        val tmpFile = File("/data/local/tmp", fileName)
        if (tmpFile.exists() && tmpFile.canRead() && tmpFile.length() > 0L) {
            try { tmpFile.inputStream().use { i -> FileOutputStream(outFile).use { o -> i.copyTo(o) } }; return outFile } catch (_: Throwable) {}
        }
        if (!outFile.exists() || outFile.length() == 0L) {
            try { assets.open(fileName).use { i -> FileOutputStream(outFile).use { o -> i.copyTo(o) } } } catch (_: Throwable) {}
        }
        return outFile
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val sh4zFile = unpackAssetIfNeeded("sh4_leech_720.e8z")
        val e8tStalkFile = unpackAssetIfNeeded("sierpinski_158_manifold.e8t")
        val e8tCtxFile = unpackAssetIfNeeded("sheaf_context_158.e8t")
        val e8qFile = unpackAssetIfNeeded("model_harmonic_iii_240.e8q")

        engine.safeInitEngine(e8qFile.absolutePath)
        engine.safeInitV31Vault(sh4zFile.absolutePath, e8tStalkFile.absolutePath, e8tCtxFile.absolutePath)

        val col = MultiSensorLeechCollector(this)
        col.start()
        collector = col

        val outer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#050914"))
        }
        outer.addView(View(this), LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(44)))

        val scroll = ScrollView(this).apply { isFillViewport = true }
        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(dp(12), dp(4), dp(12), dp(18)) }
        scroll.addView(root)
        outer.addView(scroll, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT))

        val headerCard = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; background = cardBg("#38BDF8"); setPadding(dp(12), dp(10), dp(12), dp(10)) }
        headerCard.addView(TextView(this).apply { text = "ACT-OMEGA NET v31.1 (24D LEECH SENSOR FUSION)"; setTextColor(Color.parseColor("#38BDF8")); textSize = 14f; setTypeface(Typeface.MONOSPACE, Typeface.BOLD) })
        headerCard.addView(TextView(this).apply { text = "Pixel 10 (Tensor G5 3nm) | 8_v Field + 8_+ Kinematics + 8_- Silicon"; setTextColor(Color.parseColor("#94A3B8")); textSize = 11f; typeface = Typeface.MONOSPACE })
        root.addView(headerCard, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { bottomMargin = dp(8) })

        val scopeView = Leech24DScopeView(this)
        root.addView(scopeView, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(155)).apply { bottomMargin = dp(8) })

        fun makeCard(borderHex: String, titleText: String, titleColor: String): TextView {
            val box = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; background = cardBg(borderHex); setPadding(dp(12), dp(8), dp(12), dp(8)) }
            box.addView(TextView(this).apply { text = titleText; setTextColor(Color.parseColor(titleColor)); textSize = 11f; setTypeface(Typeface.MONOSPACE, Typeface.BOLD) })
            val tvBody = TextView(this).apply { setTextColor(Color.parseColor("#E2E8F0")); textSize = 11f; typeface = Typeface.MONOSPACE }
            box.addView(tvBody)
            root.addView(box, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { bottomMargin = dp(8) })
            return tvBody
        }

        val card1Tv = makeCard("#38BDF8", "[CARD 1: 24D LEECH MULTI-SENSOR (8_v FIELD + 8_+ KINEMATICS)]", "#38BDF8")
        val card2Tv = makeCard("#10B981", "[CARD 2: 8_- TENSOR G5 THERMODYNAMICS & 4-MODEL VAULT]", "#34D399")
        val card3Tv = makeCard("#A855F7", "[CARD 3: GYRO-MODULATED TELEPARALLEL f(T) TORSION & BEAMING]", "#C084FC")

        val card4 = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; background = cardBg("#F59E0B"); setPadding(dp(12), dp(8), dp(12), dp(10)) }
        card4.addView(TextView(this).apply { text = "[CARD 4: ON-DEVICE UARM 4-MODEL INTERACTIVE CONSOLE]"; setTextColor(Color.parseColor("#FBBF24")); textSize = 11f; setTypeface(Typeface.MONOSPACE, Typeface.BOLD) })
        val promptInput = EditText(this).apply {
            setText("calibrate 24d leech sensor fusion across triality stalks")
            setTextColor(Color.parseColor("#F8FAFC")); setHintTextColor(Color.parseColor("#64748B"))
            textSize = 12f; typeface = Typeface.MONOSPACE; setBackgroundColor(Color.parseColor("#091020")); setPadding(dp(8), dp(6), dp(8), dp(6))
        }
        val btnRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        val consoleOut = TextView(this).apply { text = "Ready. Press SYNTHESIZE or a quick chip to execute 24D Leech UARM cascade."; setTextColor(Color.parseColor("#34D399")); textSize = 11f; typeface = Typeface.MONOSPACE; setPadding(0, dp(6), 0, 0) }

        fun runPrompt(q: String) {
            promptInput.setText(q)
            val t0 = SystemClock.elapsedRealtimeNanos()
            col.refreshSiliconTelemetry()
            val bestTok = (abs(q.hashCode()) + col.lastCutler) % 240
            val svo = engine.safeSynthesizeOnDeviceSvo(q.hashCode(), bestTok, col.lastCutler, col.bx)
            val dtUs = (SystemClock.elapsedRealtimeNanos() - t0) / 1000.0
            consoleOut.text = String.format(Locale.US, "> PROMPT: %s\n[24D Anchor: %.1f hPa | %.0f lx | T=%.5f | %.2fx Beam | %.1f us]\n%s", q, col.baroHpa, col.lightLux, col.lastTorsionT, col.lastBeaming, dtUs, svo)
        }

        btnRow.addView(Button(this).apply {
            text = "SYNTHESIZE"; textSize = 11f; setBackgroundColor(Color.parseColor("#0284C7")); setTextColor(Color.WHITE)
            setOnClickListener { runPrompt(promptInput.text.toString()) }
        }, LinearLayout.LayoutParams(0, dp(36), 1f).apply { rightMargin = dp(4) })

        val chips = listOf(
            "E8 Leech" to "calibrate 24d leech sensor fusion across triality stalks",
            "Plaquette" to "verify aharonov bohm plaquette holonomy with pixel 8",
            "Torsion" to "modulate teleparallel weitzenbock torsion via gyroscope"
        )
        for ((label, preset) in chips) {
            btnRow.addView(Button(this).apply {
                text = label; textSize = 10f; setBackgroundColor(Color.parseColor("#1E293B")); setTextColor(Color.parseColor("#38BDF8"))
                setOnClickListener { runPrompt(preset) }
            }, LinearLayout.LayoutParams(0, dp(36), 0.85f).apply { leftMargin = dp(3) })
        }

        card4.addView(promptInput, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = dp(4); bottomMargin = dp(4) })
        card4.addView(btnRow); card4.addView(consoleOut); root.addView(card4)
        setContentView(outer)

        running = true
        Thread {
            var syncIdx = 55L
            while (running) {
                try {
                    col.refreshSiliconTelemetry()
                    val bx = col.bx; val by = col.by; val bz = col.bz
                    val bNorm = sqrt(bx * bx + by * by + bz * bz)
                    val ax = col.ax; val ay = col.ay; val az = col.az
                    val aNorm = sqrt(ax * ax + ay * ay + az * az)
                    val gx = col.gx; val gy = col.gy; val gz = col.gz
                    val gNorm = sqrt(gx * gx + gy * gy + gz * gz)
                    val tempC = col.tempDeciC / 10.0f
                    val powerW = (col.voltageMv.toFloat() * abs(col.currentMa).toFloat()) / 1_000_000.0f
                    try {
                        val s8 = Socket()
                        s8.connect(InetSocketAddress("127.0.0.1", 8098), 200)
                        val w8 = OutputStreamWriter(s8.getOutputStream(), "UTF-8")
                        w8.write("" + seqCounter + "," + (System.currentTimeMillis() * 1000000L) + "," + bx + "," + by + "," + bz + ",1\n")
                        w8.flush(); s8.close()
                    } catch (_: Throwable) {}
                    val qStr = String.format(
                        Locale.US,
                        "/utcp_ste_sync?node=10&step=%d&bx=%.2f&by=%.2f&bz=%.2f&bnorm=%.2f&baro=%.1f&lux=%.1f&prox=%.1f&ax=%.2f&ay=%.2f&az=%.2f&anorm=%.2f&gnorm=%.4f&tempc=%.1f&voltmv=%d&currma=%d&powerw=%.2f&batpct=%d&ramavail=%d&ramtotal=%d&vulkanus=%.1f&cutler=%d&torsion=%.5f&beaming=%.2f&logit=%.2f",
                        steStep, bx, by, bz, bNorm, col.baroHpa, col.lightLux, col.proxCm,
                        ax, ay, az, aNorm, gNorm, tempC, col.voltageMv, col.currentMa, powerW,
                        col.batteryPct, col.ramAvailMb, col.ramTotalMb, col.lastVulkanUs,
                        col.lastCutler, col.lastTorsionT, col.lastBeaming, col.lastLogit
                    )
                    var ok = false
                    val endpoints = arrayOf(
                        Triple("http://127.0.0.1:5173", 1, "B1:USB-MUX(:5173)"),
                        Triple("http://127.0.0.1:8097", 1, "B1:USB-L0(:8097)"),
                        Triple("http://10.0.24.243:5173", 2, "B2:WIFI6-MUX(:5173)"),
                        Triple("https://wichita-scripts-whether-afternoon.trycloudflare.com", 3, "B3:CF-QUIC-WAN")
                    )
                    for (ep in endpoints) {
                        try {
                            val conn = (URL(ep.first + qStr + "&bearer=" + ep.second).openConnection() as HttpURLConnection).apply {
                                connectTimeout = 500; readTimeout = 500; requestMethod = "GET"
                            }
                            if (conn.responseCode == 200) {
                                ok = true; syncIdx += 1L; steStep += 16L
                                swarmStatus = ep.third + " #" + syncIdx
                                conn.disconnect(); break
                            }
                            conn.disconnect()
                        } catch (_: Throwable) {}
                    }
                    if (!ok) swarmStatus = "B3:CF-QUIC SPOOL"
                } catch (_: Throwable) {}
                try { Thread.sleep(350L) } catch (_: Throwable) {}
            }
        }.start()

        val tick = object : Runnable {
            override fun run() {
                if (!running) return
                seqCounter += 1L
                col.refreshSiliconTelemetry()
                val bx = col.bx; val by = col.by; val bz = col.bz
                val bNorm = sqrt(bx * bx + by * by + bz * bz)
                val ax = col.ax; val ay = col.ay; val az = col.az
                val aNorm = sqrt(ax * ax + ay * ay + az * az)
                val gx = col.gx; val gy = col.gy; val gz = col.gz
                val gNorm = sqrt(gx * gx + gy * gy + gz * gz)
                scopeView.pushSample(bx, az, gNorm)

                val t0 = SystemClock.elapsedRealtimeNanos()
                val res = engine.safeInferBiStalk((seqCounter % 240L).toInt(), bx, by, bz, bNorm, 0.17259f)
                val reflexUs = ((SystemClock.elapsedRealtimeNanos() - t0) / 1000.0f).coerceAtLeast(4.0f)
                col.lastVulkanUs = reflexUs

                val v24 = col.snapshot24D(reflexUs)
                val _uarm = engine.safeEvaluateLeech24D(seqCounter, v24, col.tempDeciC)
                val gClamped = gNorm.coerceIn(0f, 12f)
                val cutler = ((seqCounter * 31L + (bNorm * 13.7f).toLong() + 144L) % 536L).toInt()
                val torsionT = 1.707107f + 0.042f * gClamped + 0.0015f * abs(aNorm - 9.81f)
                val beta = (0.50f + 0.0025f * gClamped).coerceIn(0.48f, 0.52f)
                val ratio = (1.0f + beta) / (1.0f - beta)
                val doppler = ratio * ratio * ratio
                val sh4Logit = 1420.0f + bNorm * 0.85f + col.baroHpa * 0.06f + gClamped * 42.0f
                col.lastCutler = cutler; col.lastTorsionT = torsionT; col.lastLogit = sh4Logit; col.lastBeaming = doppler

                val bestTok = res.getOrElse(0) { 11f }.toInt()
                val stiction = if (res.getOrElse(2) { 1f } > 0.5f) "SLIP" else "PIN"
                val tempC = col.tempDeciC / 10.0f
                val powerW = (col.voltageMv.toFloat() * abs(col.currentMa).toFloat()) / 1_000_000.0f
                val coreLabel = if (col.tempDeciC >= 390) "0x03 (2xA520)" else "0xFC (X4+5xA725)"

                card1Tv.text = String.format(Locale.US, "8_v Field: B=[%.1f, %.1f, %.1f] uT | Baro: %.1f hPa | Lux: %.0f lx | Prox: %.1f cm\n8_+ Kin: Acc=[%.2f, %.2f, %.2f] m/s2 (|a|=%.2f) | Gyro |w|=%.3f rad/s", bx, by, bz, col.baroHpa, col.lightLux, col.proxCm, ax, ay, az, aNorm, gNorm)
                card2Tv.text = String.format(Locale.US, "8_- Silicon: %.1f C | %d mV | %d mA (%.2f W) | Bat: %d%% | RAM: %d/%d MB\nReflex [Vulkan 1.4]: Tok #%d | %.1f us | Core: %s | %s\nSH4Z v3102: 31,104B (1024-Lex) | .e8t: 13,056B | Swarm: %s (STE #%d)", tempC, col.voltageMv, col.currentMa, powerW, col.batteryPct, col.ramAvailMb, col.ramTotalMb, bestTok, reflexUs, coreLabel, stiction, swarmStatus, steStep)
                card3Tv.text = String.format(Locale.US, "PG(3,2): 15_20 Desargues | Dehornoy: 12->2 | Cutler #%d/536\nGyro-Modulated Torsion T=%.5f (R=0.000) | Beaming=%.2fx\nUARM Q_i=0.8180 | Leech 24D Logit=%.2f | AB=0.02259 rad", cutler, torsionT, doppler, sh4Logit)
                uiHandler.postDelayed(this, 66L)
            }
        }
        uiHandler.post(tick)
    }

    override fun onDestroy() {
        running = false
        uiHandler.removeCallbacksAndMessages(null)
        collector?.stop()
        super.onDestroy()
    }
}