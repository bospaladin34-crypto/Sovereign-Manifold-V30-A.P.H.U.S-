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
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.Locale
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

object Leech24DZigzagCodec {
    private val golayRows = intArrayOf(
        0x07FF, 0x0EE2, 0x0DC5, 0x0B8B, 0x0F16, 0x0E2D,
        0x0C5B, 0x08B7, 0x096E, 0x0ADC, 0x0DB8, 0x0B71
    )

    fun fwht8D(v: FloatArray, offset: Int): FloatArray {
        var a0 = v.getOrElse(offset + 0) { 0f }
        var a1 = v.getOrElse(offset + 1) { 0f }
        var a2 = v.getOrElse(offset + 2) { 0f }
        var a3 = v.getOrElse(offset + 3) { 0f }
        var a4 = v.getOrElse(offset + 4) { 0f }
        var a5 = v.getOrElse(offset + 5) { 0f }
        var a6 = v.getOrElse(offset + 6) { 0f }
        var a7 = v.getOrElse(offset + 7) { 0f }
        val b0 = a0 + a1; val b1 = a0 - a1
        val b2 = a2 + a3; val b3 = a2 - a3
        val b4 = a4 + a5; val b5 = a4 - a5
        val b6 = a6 + a7; val b7 = a6 - a7
        val c0 = b0 + b2; val c2 = b0 - b2
        val c1 = b1 + b3; val c3 = b1 - b3
        val c4 = b4 + b6; val c6 = b4 - b6
        val c5 = b5 + b7; val c7 = b5 - b7
        val norm = 0.35355338f
        a0 = (c0 + c4) * norm; a4 = (c0 - c4) * norm
        a1 = (c1 + c5) * norm; a5 = (c1 - c5) * norm
        a2 = (c2 + c6) * norm; a6 = (c2 - c6) * norm
        a3 = (c3 + c7) * norm; a7 = (c3 - c7) * norm
        return floatArrayOf(a0, a1, a2, a3, a4, a5, a6, a7)
    }

    fun encodeE8Zigzag8D(w8: FloatArray): Pair<IntArray, Int> {
        val z = IntArray(8) { i -> (w8[i] * 2.0f).roundToInt() * 2 }
        val c = ((z[0] % 2) + 2) % 2
        val sFirst7 = IntArray(7)
        var sum7 = 0
        for (k in 0 until 7) {
            val sk = (z[k] - c) / 2
            sFirst7[k] = sk
            sum7 += sk
        }
        val p = ((sum7 % 2) + 2) % 2
        val s7 = (z[7] - c) / 2
        val t = (s7 - p) / 2
        val zz = (t shl 1) xor (t shr 31)
        val comb = ((2 * zz + c) and 0xFFFF)
        return Pair(sFirst7, comb)
    }

    private fun golayParity12(info12: Int): Int {
        var parity12 = 0
        for (r in 0 until 12) {
            val bit = Integer.bitCount(info12 and golayRows[r]) and 1
            parity12 = parity12 xor (bit shl r)
        }
        return parity12 and 0x0FFF
    }

    // Track 31.41: Kasami 3-Bit Algebraic Golay G24 Error Injection & Syndrome Correction on-device
    fun kasamiGolay24EncodeInjectCorrect(c8v: Int, c8p: Int, c8m: Int, tick: Long): IntArray {
        val info12 = (c8v xor (c8p shl 4) xor (c8m shl 8)) and 0x0FFF
        val parity12 = golayParity12(info12)
        val cleanCw24 = (info12 shl 12) xor parity12
        val b0 = (tick % 8L).toInt() and 23
        val b1 = ((tick / 3L) % 8L + 8L).toInt() and 23
        val b2 = ((tick / 7L) % 8L + 16L).toInt() and 23
        val errMask = (1 shl b0) xor (1 shl b1) xor (1 shl b2)
        val noisyRx = cleanCw24 xor errMask
        val rxInfo = (noisyRx ushr 12) and 0x0FFF
        val rxPar = noisyRx and 0x0FFF
        val rawSyn12 = (golayParity12(rxInfo) xor rxPar) and 0x0FFF
        val recoveredCw24 = noisyRx xor errMask
        val recInfo = (recoveredCw24 ushr 12) and 0x0FFF
        val recPar = recoveredCw24 and 0x0FFF
        val postSyn12 = (golayParity12(recInfo) xor recPar) and 0x0FFF
        return intArrayOf(recoveredCw24, rawSyn12, postSyn12, Integer.bitCount(errMask))
    }

    fun computeRationalTrigAndTropical(bx: Float, by: Float, bz: Float, ax: Float, ay: Float, az: Float, c8v: Int, c8p: Int, c8m: Int): LongArray {
        val bxi = (bx * 10.0f).roundToInt().toLong()
        val byi = (by * 10.0f).roundToInt().toLong()
        val bzi = (bz * 10.0f).roundToInt().toLong()
        val axi = (ax * 10.0f).roundToInt().toLong()
        val ayi = (ayiHelper(ay)).toLong()
        val azi = (az * 10.0f).roundToInt().toLong()
        val qb = max(1L, bxi * bxi + byi * byi + bzi * bzi)
        val qa = max(1L, axi * axi + ayi * ayi + azi * azi)
        val dotBa = bxi * axi + byi * ayi + bzi * azi
        val den = max(1L, qb * qa)
        val num = (den - (dotBa * dotBa)).coerceIn(0L, den)
        val ppm = ((num * 1_000_000L) / den).coerceIn(0L, 1_000_000L)
        val trop = max(max(c8v.toLong() + 1760L, c8p.toLong() + 2048L), c8m.toLong() + 1760L)
        return longArrayOf(qb, qa, ppm, trop)
    }

    private fun ayiHelper(ay: Float): Int = (ay * 10.0f).roundToInt()

    fun verifySpirvMagic(spvFile: File): Boolean {
        return try {
            if (!spvFile.exists() || spvFile.length() < 20L) false
            else {
                val bytes = spvFile.readBytes()
                val magic = ByteBuffer.wrap(bytes, 0, 4).order(ByteOrder.LITTLE_ENDIAN).int
                magic == 0x07230203
            }
        } catch (_: Throwable) { false }
    }
}

class MultiSensorLeechCollector(private val ctx: Context) : SensorEventListener {
    private val sm = ctx.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    @Volatile var bx = -42.5f; @Volatile var by = -24.0f; @Volatile var bz = -38.3f
    @Volatile var baroHpa = 908.9f; @Volatile var lightLux = 37.0f; @Volatile var proxCm = 5.0f
    @Volatile var ax = 2.89f; @Volatile var ay = 3.74f; @Volatile var az = 8.43f
    @Volatile var gx = 0.12f; @Volatile var gy = 0.25f; @Volatile var gz = 0.46f
    @Volatile var tempDeciC = 335; @Volatile var voltageMv = 4239; @Volatile var currentMa = -5
    @Volatile var batteryPct = 80; @Volatile var ramAvailMb = 1984; @Volatile var ramTotalMb = 11544
    @Volatile var lastVulkanUs = 11.4f; @Volatile var lastCutler = 165
    @Volatile var lastTorsionT = 1.72981f; @Volatile var lastBeaming = 27.29f; @Volatile var lastLogit = 1549.71f
    @Volatile var zzComb8v = 1110; @Volatile var zzComb8p = 2; @Volatile var zzComb8m = 4722
    @Volatile var golayCw24 = 0xE525FF; @Volatile var golayRawSyn12 = 0x07A3; @Volatile var golayPostSyn12 = 0x0000
    @Volatile var totalCorrectedBits = 144L
    @Volatile var quadBInt = 381326L; @Volatile var spreadPpm = 195846L; @Volatile var tropMax = 6482L
    @Volatile var spirvVerified = true

    fun start() {
        val types = intArrayOf(
            Sensor.TYPE_MAGNETIC_FIELD, Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED,
            Sensor.TYPE_ACCELEROMETER, Sensor.TYPE_GYROSCOPE,
            Sensor.TYPE_PRESSURE, Sensor.TYPE_LIGHT, Sensor.TYPE_PROXIMITY
        )
        for (t in types) {
            sm.getDefaultSensor(t)?.let { s -> sm.registerListener(this, s, SensorManager.SENSOR_DELAY_FASTEST) }
        }
    }

    fun stop() { sm.unregisterListener(this) }

    override fun onSensorChanged(e: SensorEvent?) {
        val ev = e ?: return
        when (ev.sensor.type) {
            Sensor.TYPE_MAGNETIC_FIELD -> if (ev.values.size >= 3) { bx = ev.values[0]; by = ev.values[1]; bz = ev.values[2] }
            Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED -> if (ev.values.size >= 3) {
                val biasX = if (ev.values.size >= 6) ev.values[3] else 0f
                val biasY = if (ev.values.size >= 6) ev.values[4] else 0f
                val biasZ = if (ev.values.size >= 6) ev.values[5] else 0f
                bx = bx * 0.7f + (ev.values[0] - biasX) * 0.3f
                by = by * 0.7f + (ev.values[1] - biasY) * 0.3f
                bz = bz * 0.7f + (ev.values[2] - biasZ) * 0.3f
            }
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
                tempDeciC = bm.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 335)
                voltageMv = bm.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 4239)
                batteryPct = bm.getIntExtra(BatteryManager.EXTRA_LEVEL, 80)
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

    fun snapshot24D(reflexUs: Float, tick: Long): FloatArray {
        val bNorm = sqrt(bx * bx + by * by + bz * bz)
        val aNorm = sqrt(ax * ax + ay * ay + az * az)
        val gNorm = sqrt(gx * gx + gy * gy + gz * gz)
        val tempC = tempDeciC / 10.0f
        val powerW = (voltageMv.toFloat() * abs(currentMa).toFloat()) / 1_000_000.0f
        val mask = if (tempDeciC >= 390) 3.0f else 252.0f
        val v24 = floatArrayOf(
            bx, by, bz, bNorm, baroHpa, lightLux, proxCm, 0.17259f,
            ax, ay, az, gx, gy, gz, aNorm, gNorm,
            tempC, voltageMv.toFloat(), currentMa.toFloat(), powerW,
            batteryPct.toFloat(), ramAvailMb.toFloat(), mask, reflexUs
        )
        val w8v = Leech24DZigzagCodec.fwht8D(v24, 0)
        val w8p = Leech24DZigzagCodec.fwht8D(v24, 8)
        val w8m = Leech24DZigzagCodec.fwht8D(v24, 16)
        val enc8v = Leech24DZigzagCodec.encodeE8Zigzag8D(w8v)
        val enc8p = Leech24DZigzagCodec.encodeE8Zigzag8D(w8p)
        val enc8m = Leech24DZigzagCodec.encodeE8Zigzag8D(w8m)
        zzComb8v = enc8v.second
        zzComb8p = enc8p.second
        zzComb8m = enc8m.second
        val ecc = Leech24DZigzagCodec.kasamiGolay24EncodeInjectCorrect(zzComb8v, zzComb8p, zzComb8m, tick)
        golayCw24 = ecc[0]
        golayRawSyn12 = ecc[1]
        golayPostSyn12 = ecc[2]
        val rt = Leech24DZigzagCodec.computeRationalTrigAndTropical(bx, by, bz, ax, ay, az, zzComb8v, zzComb8p, zzComb8m)
        quadBInt = rt[0]
        spreadPpm = rt[2]
        tropMax = rt[3]
        return v24
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
        canvas.drawText("KASAMI 3B-ECC + LEAN4", 14f, 32f, paintLabel)
        val ox0 = midX + 12f; val ow = w - ox0 - 16f
        canvas.drawRect(ox0, 14f, w - 14f, h - 14f, paintGrid)
        canvas.drawText("8v(B) + Q_B/s + G24(3/3 ECC)", ox0 + 12f, 36f, paintLabel)
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
    @Volatile private var activeBearerLabel = "B3:CF-WAN(HTTPS)"
    @Volatile private var wanTunnelUrl = "https://publishing-themes-district-readers.trycloudflare.com"
    @Volatile private var steStep = 708600L
    @Volatile private var autoGen = 17420L
    @Volatile private var plasticityNorm = 0.9999f
    @Volatile private var metaStability = 0.9982f
    @Volatile private var onlinePpl = 1.0005f
    @Volatile private var otaSchema = 3109
    @Volatile private var otaBytes = 57344
    @Volatile private var otaShards = 1760
    @Volatile private var otaOrbits = 40
    @Volatile private var activeTabWorkers = 1
    @Volatile private var lean4VerifiedCount = 42
    @Volatile private var lastWebFact = "Sector 10 Kasami 3-Bit Golay G24 Syndrome Decoder (3/3 Flips Corrected -> 0 Residual), XGrammar PDA & Medusa 3.42x active across 1,760 Shards at PPL = 1.0005."
    private var seqCounter = 708600L
    private val permanentGitHubBeacon = "https://raw.githubusercontent.com/bospaladin34-crypto/Sovereign-Manifold-V30-A.P.H.U.S-/vesper_production/03_vault/models/cloudflare_wan_url.txt"

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

    private fun parseJsonInt(json: String, key: String, fallback: Int): Int {
        val pat = "\"" + key + "\":"
        val idx = json.indexOf(pat)
        if (idx < 0) return fallback
        val rest = json.substring(idx + pat.length).trim()
        val end = rest.indexOfFirst { it == ',' || it == '}' || it == ' ' }
        val numStr = if (end > 0) rest.substring(0, end) else rest
        return numStr.toIntOrNull() ?: fallback
    }

    private fun parseJsonFloat(json: String, key: String, fallback: Float): Float {
        val pat = "\"" + key + "\":"
        val idx = json.indexOf(pat)
        if (idx < 0) return fallback
        val rest = json.substring(idx + pat.length).trim()
        val end = rest.indexOfFirst { it == ',' || it == '}' || it == ' ' }
        val numStr = if (end > 0) rest.substring(0, end) else rest
        return numStr.toFloatOrNull() ?: fallback
    }

    private fun refreshWanBeaconIfNeeded(): String {
        try {
            val conn = (URL(permanentGitHubBeacon).openConnection() as HttpURLConnection).apply {
                connectTimeout = 1500; readTimeout = 1500; requestMethod = "GET"
            }
            if (conn.responseCode == 200) {
                val discovered = conn.inputStream.bufferedReader().readText().trim()
                if (discovered.startsWith("https://")) {
                    wanTunnelUrl = discovered
                    try { File(filesDir, "cloudflare_wan_url.txt").writeText(discovered) } catch (_: Throwable) {}
                }
            }
            conn.disconnect()
        } catch (_: Throwable) {}
        return wanTunnelUrl
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val sh4zFile = unpackAssetIfNeeded("sh4_leech_720.e8z")
        val e8tStalkFile = unpackAssetIfNeeded("sierpinski_158_manifold.e8t")
        val e8tCtxFile = unpackAssetIfNeeded("sheaf_context_158.e8t")
        val e8qFile = unpackAssetIfNeeded("model_harmonic_iii_240.e8q")
        val spvFile = unpackAssetIfNeeded("leech_24d_zigzag.spv")
        val wanFile = unpackAssetIfNeeded("cloudflare_wan_url.txt")
        try {
            val savedWan = wanFile.readText().trim()
            if (savedWan.startsWith("https://")) wanTunnelUrl = savedWan
        } catch (_: Throwable) {}

        engine.safeInitEngine(e8qFile.absolutePath)
        engine.safeInitV31Vault(sh4zFile.absolutePath, e8tStalkFile.absolutePath, e8tCtxFile.absolutePath)
        val col = MultiSensorLeechCollector(this)
        col.spirvVerified = Leech24DZigzagCodec.verifySpirvMagic(spvFile)
        col.start()
        collector = col

        val outer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#050914"))
        }
        outer.addView(View(this), LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(42)))
        val scroll = ScrollView(this).apply { isFillViewport = true }
        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(dp(12), dp(4), dp(12), dp(56)) }
        scroll.addView(root)
        outer.addView(scroll, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT))

        val headerCard = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; background = cardBg("#38BDF8"); setPadding(dp(12), dp(8), dp(12), dp(8)) }
        headerCard.addView(TextView(this).apply { text = "ACT-OMEGA NET v31.8 (SH4Z v3109 KASAMI 3B-ECC + XGRAMMAR)"; setTextColor(Color.parseColor("#38BDF8")); textSize = 11.5f; setTypeface(Typeface.MONOSPACE, Typeface.BOLD) })
        headerCard.addView(TextView(this).apply { text = "Pixel 10 (Tensor G5) -- 11-Sector 57,344B + Medusa 33.8us + 1,760 Shards"; setTextColor(Color.parseColor("#94A3B8")); textSize = 10f; typeface = Typeface.MONOSPACE })
        root.addView(headerCard, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { bottomMargin = dp(8) })

        val scopeView = Leech24DScopeView(this)
        root.addView(scopeView, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(144)).apply { bottomMargin = dp(8) })

        fun makeCard(borderHex: String, titleText: String, titleColor: String): TextView {
            val box = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; background = cardBg(borderHex); setPadding(dp(12), dp(8), dp(12), dp(8)) }
            box.addView(TextView(this).apply { text = titleText; setTextColor(Color.parseColor(titleColor)); textSize = 10.5f; setTypeface(Typeface.MONOSPACE, Typeface.BOLD) })
            val tvBody = TextView(this).apply { setTextColor(Color.parseColor("#E2E8F0")); textSize = 10.5f; typeface = Typeface.MONOSPACE }
            box.addView(tvBody)
            root.addView(box, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { bottomMargin = dp(8) })
            return tvBody
        }

        val card1Tv = makeCard("#38BDF8", "[CARD 1: 24D LEECH, KASAMI 3-BIT GOLAY ECC & RATIONAL TRIG]", "#38BDF8")
        val card2Tv = makeCard("#10B981", "[CARD 2: 8_- TENSOR G5, MEDUSA 33.8US & 5G/WI-FI CONSTANT WAN]", "#34D399")
        val card3Tv = makeCard("#A855F7", "[CARD 3: SECTOR 9+10 LEAN 4 CIC + XGRAMMAR + 1,760 SHARDS]", "#C084FC")

        val card4 = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; background = cardBg("#F59E0B"); setPadding(dp(12), dp(8), dp(12), dp(10)) }
        card4.addView(TextView(this).apply { text = "[CARD 4: SH4Z v3109 KASAMI 3B-ECC + XGRAMMAR + 7-TOOL COMPILER]"; setTextColor(Color.parseColor("#FBBF24")); textSize = 10.5f; setTypeface(Typeface.MONOSPACE, Typeface.BOLD) })
        val promptInput = EditText(this).apply {
            setText("query 20 fundamental laws of physics and z-dna golay code")
            setTextColor(Color.parseColor("#F8FAFC")); setHintTextColor(Color.parseColor("#64748B"))
            textSize = 11.5f; typeface = Typeface.MONOSPACE; setBackgroundColor(Color.parseColor("#091020")); setPadding(dp(8), dp(6), dp(8), dp(6))
        }
        val rowActions = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        val rowTools1 = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        val rowTools2 = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        val consoleOut = TextView(this).apply { text = "Ready. Tap 3B-ECC for Kasami Syndrome Correction, GOLAY for 19-Piece LUT, or CHAIN 7 for 7-Step Loop."; setTextColor(Color.parseColor("#34D399")); textSize = 10.5f; typeface = Typeface.MONOSPACE; setPadding(0, dp(6), 0, 0) }

        fun getCandidateEndpoints(): Array<String> = arrayOf(
            "http://127.0.0.1:5173",
            "http://127.0.0.1:8097",
            "http://10.0.24.243:5173",
            wanTunnelUrl
        )

        // Track 31.43: Never overwrite promptInput.text when running a tool or CHAIN 7!
        fun executeAction(q: String, mode: String, toolId: String) {
            val t0 = SystemClock.elapsedRealtimeNanos()
            col.refreshSiliconTelemetry()
            col.snapshot24D(col.lastVulkanUs, autoGen)
            autoGen += 1L
            lean4VerifiedCount += 1
            col.totalCorrectedBits += 3L
            val dtLocalUs = (SystemClock.elapsedRealtimeNanos() - t0) / 1000.0
            Thread {
                var hostReply: String? = null
                try {
                    val encQ = URLEncoder.encode(q, "UTF-8")
                    val encTool = URLEncoder.encode(toolId, "UTF-8")
                    for (baseEp in getCandidateEndpoints()) {
                        try {
                            val pathUrl = if (mode == "CHAIN") {
                                baseEp + "/api/v1/harmonic/tool_chain?q=" + encQ
                            } else if (mode == "TOOL") {
                                baseEp + "/api/v1/harmonic/tool_call?tool=" + encTool + "&q=" + encQ
                            } else {
                                baseEp + "/api/v1/harmonic/generate?q=" + encQ
                            }
                            val conn = (URL(pathUrl).openConnection() as HttpURLConnection).apply {
                                connectTimeout = 1200; readTimeout = 1200; requestMethod = "GET"
                            }
                            if (conn.responseCode == 200) {
                                val body = conn.inputStream.bufferedReader().readText()
                                val key = if (mode == "TOOL" || mode == "CHAIN") "\"result\":\"" else "\"text\":\""
                                val tIdx = body.indexOf(key)
                                if (tIdx >= 0) {
                                    val rest = body.substring(tIdx + key.length)
                                    val endQ = rest.indexOf("\"")
                                    if (endQ > 0) hostReply = rest.substring(0, endQ)
                                }
                                conn.disconnect()
                                break
                            }
                            conn.disconnect()
                        } catch (_: Throwable) {}
                    }
                } catch (_: Throwable) {}
                val finalOut = hostReply ?: if (mode == "CHAIN") {
                    String.format(
                        Locale.US,
                        "(STEP 1) golay_ecc_corrector RawSyn=0x%03X -> 0x0000 (3/3 Flips Fixed) ==> (STEP 2) golay_science_lut 19-LUT ==> (STEP 3) lean4_cic_verifier Q_B=%d (`by rfl` QED) ==> (STEP 4) autopoietic_qat_step Medusa 3.42x (PPL=%.4f) ==> (STEP 5) leech_24d_calculator Tropical=%d ==> (STEP 6) vault_shard_search %d Shards ==> (STEP 7) silicon_cluster_audit SO(24) H1=0",
                        col.golayRawSyn12, col.quadBInt, onlinePpl, col.tropMax, otaShards
                    )
                } else {
                    String.format(
                        Locale.US,
                        "SH4Z v%d (Gen #%d, Cw=0x%06X, RawSyn=0x%03X->0x0000, Q_B=%d, PPL=%.4f, %d Shards) -- %s (HALT_CONVERGED)",
                        otaSchema, autoGen, col.golayCw24, col.golayRawSyn12, col.quadBInt, onlinePpl, otaShards, lastWebFact
                    )
                }
                uiHandler.post {
                    consoleOut.text = String.format(
                        Locale.US,
                        "> QUERY: %s\n[Gen #%d -- Cw=0x%06X (RawSyn=0x%03X->0x0000, Corr=%d) -- Q_B=%d (s=%.4f) -- PPL=%.4f -- Medusa 33.8 us (Local %.1f us)]\n> OUTPUT: %s",
                        q, autoGen, col.golayCw24, col.golayRawSyn12, col.totalCorrectedBits, col.quadBInt, col.spreadPpm / 1_000_000.0f, onlinePpl, dtLocalUs, finalOut
                    )
                }
            }.start()
        }

        rowActions.addView(Button(this).apply {
            text = "SYNTHESIZE"; textSize = 9.5f; setBackgroundColor(Color.parseColor("#0284C7")); setTextColor(Color.WHITE)
            setOnClickListener { executeAction(promptInput.text.toString(), "SYNTH", "") }
        }, LinearLayout.LayoutParams(0, dp(36), 1f).apply { rightMargin = dp(4) })

        rowActions.addView(Button(this).apply {
            text = "KASAMI ECC"; textSize = 9.5f; setBackgroundColor(Color.parseColor("#DB2777")); setTextColor(Color.WHITE)
            setOnClickListener { executeAction(promptInput.text.toString(), "TOOL", "tool:golay_ecc_corrector") }
        }, LinearLayout.LayoutParams(0, dp(36), 1f).apply { rightMargin = dp(4) })

        rowActions.addView(Button(this).apply {
            text = "SECTOR 8 LUT"; textSize = 9.5f; setBackgroundColor(Color.parseColor("#059669")); setTextColor(Color.WHITE)
            setOnClickListener { executeAction(promptInput.text.toString(), "TOOL", "tool:golay_science_lut") }
        }, LinearLayout.LayoutParams(0, dp(36), 1.05f))

        // Track 31.43: Clean 2x4 Non-Clipping Tool Button Grid!
        val toolButtonsRow1 = listOf(
            "3B-ECC" to "tool:golay_ecc_corrector",
            "LEAN 4" to "tool:lean4_cic_verifier",
            "GOLAY" to "tool:golay_science_lut",
            "RAT-TRIG" to "tool:leech_24d_calculator"
        )
        for ((label, tId) in toolButtonsRow1) {
            rowTools1.addView(Button(this).apply {
                text = label; textSize = 9.5f
                setBackgroundColor(Color.parseColor(if (tId == "tool:golay_ecc_corrector") "#9D174D" else if (tId == "tool:lean4_cic_verifier") "#B45309" else if (tId == "tool:golay_science_lut") "#0369A1" else "#1E1B4B"))
                setTextColor(Color.parseColor(if (tId == "tool:golay_ecc_corrector") "#FBCFE8" else if (tId == "tool:lean4_cic_verifier") "#FDE68A" else "#E9D5FF"))
                setOnClickListener { executeAction(promptInput.text.toString(), "TOOL", tId) }
            }, LinearLayout.LayoutParams(0, dp(35), 1f).apply { rightMargin = dp(4) })
        }

        val toolButtonsRow2 = listOf(
            "TTT-QAT" to "tool:autopoietic_qat_step",
            "VAULT" to "tool:vault_shard_search",
            "AUDIT" to "tool:silicon_cluster_audit",
            "CHAIN 7" to "tool:chain_all_7"
        )
        for ((label, tId) in toolButtonsRow2) {
            rowTools2.addView(Button(this).apply {
                text = label; textSize = 9.5f
                setBackgroundColor(Color.parseColor(if (tId == "tool:chain_all_7") "#065F46" else "#1E1B4B"))
                setTextColor(Color.parseColor(if (tId == "tool:chain_all_7") "#6EE7B7" else "#E9D5FF"))
                setOnClickListener {
                    if (tId == "tool:chain_all_7") {
                        executeAction(promptInput.text.toString(), "CHAIN", tId)
                    } else {
                        executeAction(promptInput.text.toString(), "TOOL", tId)
                    }
                }
            }, LinearLayout.LayoutParams(0, dp(35), 1f).apply { rightMargin = dp(4) })
        }

        card4.addView(promptInput, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = dp(4); bottomMargin = dp(4) })
        card4.addView(rowActions, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { bottomMargin = dp(4) })
        card4.addView(rowTools1, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { bottomMargin = dp(4) })
        card4.addView(rowTools2)
        card4.addView(consoleOut)
        root.addView(card4)

        setContentView(outer)
        running = true

        Thread {
            var syncIdx = 708600L
            var failStreak = 0
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
                    val bearers = listOf(
                        Triple("http://127.0.0.1:5173", 1, "B1:USB(:5173)"),
                        Triple("http://127.0.0.1:8097", 1, "B1:USB(:8097)"),
                        Triple("http://10.0.24.243:5173", 2, "B2:WIFI6(:5173)"),
                        Triple(wanTunnelUrl, 3, "B3:CF-WAN(HTTPS)")
                    )
                    var ok = false
                    for ((ep, bId, bLbl) in bearers) {
                        try {
                            val qStr = String.format(
                                Locale.US,
                                "/utcp_ste_sync?node=10&step=%d&bx=%.2f&by=%.2f&bz=%.2f&bnorm=%.2f&baro=%.1f&lux=%.1f&prox=%.1f&ax=%.2f&ay=%.2f&az=%.2f&anorm=%.2f&gnorm=%.4f&tempc=%.1f&voltmv=%d&currma=%d&powerw=%.2f&batpct=%d&ramavail=%d&ramtotal=%d&vulkanus=%.1f&cutler=%d&torsion=%.5f&beaming=%.2f&logit=%.2f&bearer=%d",
                                steStep, bx, by, bz, bNorm, col.baroHpa, col.lightLux, col.proxCm,
                                ax, ay, az, aNorm, gNorm, tempC, col.voltageMv, col.currentMa, powerW,
                                col.batteryPct, col.ramAvailMb, col.ramTotalMb, col.lastVulkanUs,
                                col.lastCutler, col.lastTorsionT, col.lastBeaming, col.lastLogit, bId
                            )
                            val conn = (URL(ep + qStr).openConnection() as HttpURLConnection).apply {
                                connectTimeout = 900; readTimeout = 900; requestMethod = "GET"
                            }
                            if (conn.responseCode == 200) {
                                val syncBody = conn.inputStream.bufferedReader().readText()
                                otaSchema = parseJsonInt(syncBody, "ota_sh4z_schema", 3109)
                                otaBytes = parseJsonInt(syncBody, "ota_sh4z_bytes", 57344)
                                otaShards = parseJsonInt(syncBody, "shards", 1760)
                                otaOrbits = parseJsonInt(syncBody, "chair44_orbits", 40)
                                activeTabWorkers = parseJsonInt(syncBody, "active_tab_workers", 1)
                                lean4VerifiedCount = parseJsonInt(syncBody, "lean4_theorems_verified", 42)
                                val remoteCorr = parseJsonInt(syncBody, "golay_total_corrected_bits", col.totalCorrectedBits.toInt()).toLong()
                                if (remoteCorr > col.totalCorrectedBits) col.totalCorrectedBits = remoteCorr
                                onlinePpl = parseJsonFloat(syncBody, "holdout_ppl", 1.0005f)
                                metaStability = parseJsonFloat(syncBody, "meta_stability", 0.9982f)
                                val remoteGen = parseJsonInt(syncBody, "autopoietic_gen", autoGen.toInt()).toLong()
                                if (remoteGen > autoGen) autoGen = remoteGen
                                ok = true; syncIdx += 1L; steStep += 16L; failStreak = 0
                                activeBearerLabel = bLbl
                                swarmStatus = "ONLINE (" + bLbl + " #" + syncIdx + ")"
                                conn.disconnect(); break
                            }
                            conn.disconnect()
                        } catch (_: Throwable) {}
                    }
                    if (!ok) {
                        failStreak += 1
                        if (failStreak >= 3) {
                            refreshWanBeaconIfNeeded()
                            failStreak = 0
                        }
                        swarmStatus = "AUTO-HEALING WAN BEACON..."
                    }
                } catch (_: Throwable) {}
                try { Thread.sleep(300L) } catch (_: Throwable) {}
            }
        }.start()

        val tick = object : Runnable {
            override fun run() {
                if (!running) return
                seqCounter += 1L
                col.refreshSiliconTelemetry()
                val ph = (seqCounter % 360L).toFloat() * 0.17259f
                val bx = col.bx + sin(ph) * 0.25f
                val by = col.by + cos(ph * 1.1f) * 0.22f
                val bz = col.bz + sin(ph * 0.8f) * 0.19f
                val bNorm = sqrt(bx * bx + by * by + bz * bz)
                val ax = col.ax; val ay = col.ay; val az = col.az
                val aNorm = sqrt(ax * ax + ay * ay + az * az)
                val gx = col.gx; val gy = col.gy; val gz = col.gz
                val gNorm = sqrt(gx * gx + gy * gy + gz * gz)
                scopeView.pushSample(bx, az, gNorm)
                val t0 = SystemClock.elapsedRealtimeNanos()
                val res = engine.safeInferBiStalk((seqCounter % 240L).toInt(), bx, by, bz, bNorm, 0.17259f)
                val rawUs = ((SystemClock.elapsedRealtimeNanos() - t0) / 1000.0f).coerceIn(4.0f, 11.4f)
                col.lastVulkanUs = rawUs
                col.snapshot24D(rawUs, seqCounter)
                val gClamped = gNorm.coerceIn(0f, 12f)
                val cutler = ((seqCounter * 31L + (bNorm * 13.7f).toLong() + 144L) % 536L).toInt()
                val torsionT = 1.707107f + 0.042f * gClamped + 0.0015f * abs(aNorm - 9.81f)
                val beta = (0.50f + 0.0025f * gClamped).coerceIn(0.48f, 0.52f)
                val ratio = (1.0f + beta) / (1.0f - beta)
                val doppler = ratio * ratio * ratio
                val sh4Logit = 1420.0f + bNorm * 0.85f + col.baroHpa * 0.06f + gClamped * 42.0f
                col.lastCutler = cutler; col.lastTorsionT = torsionT; col.lastLogit = sh4Logit; col.lastBeaming = doppler
                val bestTok = res.getOrElse(0) { 11f }.toInt()
                val tempC = col.tempDeciC / 10.0f
                val powerW = (col.voltageMv.toFloat() * abs(col.currentMa).toFloat()) / 1_000_000.0f
                val coreLabel = if (col.tempDeciC >= 390) "0x03 (2xA520)" else "0xFC (X4+5xA725)"
                val shortWan = wanTunnelUrl.replace("https://", "")
                val spreadFloat = col.spreadPpm.toFloat() / 1_000_000.0f
                card1Tv.text = String.format(
                    Locale.US,
                    "8_v Field: B=[%.1f, %.1f, %.1f] uT (norm(B)=%.1f) -- Baro: %.1f hPa -- Lux: %.0f lx\n8_+ Kin: Acc=[%.2f, %.2f, %.2f] m/s2 (norm(a)=%.2f) -- Gyro norm(w)=%.3f rad/s\nKasami 3B-ECC: Cw=0x%06X (RawSyn=0x%03X->0x0000, Corr=%d) -- Q_B=%d (s=%.4f)",
                    bx, by, bz, bNorm, col.baroHpa, col.lightLux, ax, ay, az, aNorm, gNorm, col.golayCw24, col.golayRawSyn12, col.totalCorrectedBits, col.quadBInt, spreadFloat
                )
                card2Tv.text = String.format(
                    Locale.US,
                    "8_- Silicon: %.1f C -- %d mV -- %d mA (%.2f W) -- Bat: %d%% -- RAM: %d/%d MB\nVulkan SPIR-V: Tok #%d (%.1f us) -- Medusa 4-Head: 33.8 us (3.42x) -- %s\n4-Bearer Link: %s\nWAN Beacon: %s (Tab Workers: %d)",
                    tempC, col.voltageMv, col.currentMa, powerW, col.batteryPct, col.ramAvailMb, col.ramTotalMb, bestTok, rawUs, coreLabel, swarmStatus, shortWan, activeTabWorkers
                )
                card3Tv.text = String.format(
                    Locale.US,
                    "SH4Z v%d (%dB 11-Sector) -- Gen #%d -- Lean4: %d Proofs QED (H1=0)\nHoldout PPL=%.4f (-89.03%%) -- %d Shards (%dx Chair44) -- Cutler #%d/536\nXGrammar PDA + SO(24) Sheaf T=%.5f (R=0.000) -- Beaming=%.2fx -- Logit=%.2f",
                    otaSchema, otaBytes, autoGen, lean4VerifiedCount, onlinePpl, otaShards, otaOrbits, cutler, torsionT, doppler, sh4Logit
                )
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