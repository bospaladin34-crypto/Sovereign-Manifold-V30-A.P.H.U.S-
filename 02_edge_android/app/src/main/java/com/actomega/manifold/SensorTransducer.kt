package com.actomega.manifold

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager

class SensorTransducer(
    context: Context,
    private val onFrame: (bx: Float, by: Float, bz: Float) -> Unit
) : SensorEventListener {
    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val magSensor = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED)
        ?: sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

    fun start() {
        magSensor?.let {
            sensorManager.registerListener(this, it, 66666) // ~15 Hz carrier sampling (66.6 ms)
        }
    }

    fun stop() {
        sensorManager.unregisterListener(this)
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return
        val bx = event.values.getOrNull(0) ?: 0f
        val by = event.values.getOrNull(1) ?: 0f
        val bz = event.values.getOrNull(2) ?: 0f
        onFrame(bx, by, bz)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}