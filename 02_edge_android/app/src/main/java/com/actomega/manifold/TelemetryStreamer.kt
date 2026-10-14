package com.actomega.manifold

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.net.wifi.WifiManager
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.channels.Channel
import java.io.PrintWriter
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket

class TelemetryStreamer(
    private val context: Context? = null,
    private val loopbackIp: String = "127.0.0.1",
    private val wifiLanIp: String = "10.0.24.243",
    private val port: Int = 8098
) {
    private val channel = Channel<String>(capacity = 256, onBufferOverflow = BufferOverflow.DROP_OLDEST)
    private var job: Job? = null
    var isConnected: Boolean = false
        private set

    @Volatile
    var activeHostIp: String = loopbackIp
        private set

    @Volatile
    private var discoveredIp: String? = null

    private var multicastLock: WifiManager.MulticastLock? = null
    private var nsdManager: NsdManager? = null



    private fun startDiscovery() {
        if (context != null) {
            try {
                val wifi = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                multicastLock = wifi?.createMulticastLock("actomega_mDNS")?.apply {
                    setReferenceCounted(true)
                    acquire()
                }

                nsdManager = context.getSystemService(Context.NSD_SERVICE) as? NsdManager
                val listener = object : NsdManager.DiscoveryListener {
                    override fun onDiscoveryStarted(regType: String) {}
                    override fun onServiceFound(service: NsdServiceInfo) {
                        try {
                            nsdManager?.resolveService(service, object : NsdManager.ResolveListener {
                                override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {}
                                override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
                                    val host = serviceInfo.host?.hostAddress
                                    if (!host.isNullOrBlank()) {
                                        discoveredIp = host
                                    }
                                }
                            })
                        } catch (_: Exception) {}
                    }
                    override fun onServiceLost(service: NsdServiceInfo) {}
                    override fun onDiscoveryStopped(serviceType: String) {}
                    override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {}
                    override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {}
                }
                nsdManager?.discoverServices("_actomega._tcp", NsdManager.PROTOCOL_DNS_SD, listener)
            } catch (_: Exception) {}
        }

        // Parallel fast UDP broadcast probe on port 8098
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val socket = DatagramSocket()
                socket.broadcast = true
                socket.soTimeout = 1500
                val data = "ACTOMEGA_DISCOVERY".toByteArray()
                val packet = DatagramPacket(data, data.size, InetAddress.getByName("255.255.255.255"), port)
                socket.send(packet)

                val buf = ByteArray(128)
                val reply = DatagramPacket(buf, buf.size)
                socket.receive(reply)
                val replyStr = String(reply.data, 0, reply.length)
                if (replyStr.startsWith("ACTOMEGA_HOST")) {
                    discoveredIp = reply.address.hostAddress
                }
                socket.close()
            } catch (_: Exception) {}
        }
    }

    fun start() {
        startDiscovery()
        startDiscovery()
        job = CoroutineScope(Dispatchers.IO).launch {
            var socket: Socket? = null
            var writer: PrintWriter? = null

            while (isActive) {
                val line = channel.receive()

                if (socket == null || socket.isClosed || !socket.isConnected || writer == null) {
                    try {
                        val s = Socket()
                        s.tcpNoDelay = true
                        s.keepAlive = true
                        s.soTimeout = 3000
                        try {
                            s.connect(InetSocketAddress(loopbackIp, port), 300)
                            activeHostIp = loopbackIp
                        } catch (_: Exception) {
                            val targetIp = discoveredIp ?: wifiLanIp
                            s.connect(InetSocketAddress(targetIp, port), 1000)
                            activeHostIp = targetIp
                        }
                        socket = s
                        writer = PrintWriter(s.getOutputStream(), true)
                        isConnected = true
                    } catch (_: Exception) {
                        socket = null
                        writer = null
                        isConnected = false
                        delay(500)
                        continue
                    }
                }

                try {
                    writer?.println(line)
                    if (writer?.checkError() == true) {
                        throw java.io.IOException("Socket stream error")
                    }
                    isConnected = true
                } catch (e: Exception) {
                    try { socket?.close() } catch (_: Exception) {}
                    socket = null
                    writer = null
                    isConnected = false
                }
            }
        }
    }

    fun enqueue(seq: Long, bx: Float, by: Float, bz: Float) {
        val line = "$seq,${System.currentTimeMillis()},$bx,$by,$bz"
        channel.trySend(line)
    }

    fun enqueue(line: String) {
        channel.trySend(line)
    }

    fun post(packetJson: String) {
        channel.trySend(packetJson)
    }

    fun stop() {
        job?.cancel()
        job = null
        isConnected = false
        try {
            multicastLock?.release()
        } catch (_: Exception) {}
    }
}