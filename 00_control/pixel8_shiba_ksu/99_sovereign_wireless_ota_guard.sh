#!/system/bin/sh
# ACT-OMEGA v71.1.0 Persistent KernelSU Boot & Stationary Multi-Bearer Guard (Pixel 8 3A121FDJH00BW5)
# Supports Tri-Bearer Stationary Edge Compute (:8098) & Headless Telemetry Streaming (:8097):
#   - Bearer 1: USB Loopback / ADB Forward-Reverse (127.0.0.1:8098 <-> 127.0.0.1:8097)
#   - Bearer 2: Windows 11 Wi-Fi 6 Direct Hotspot "GARLOCK00 0975" (192.168.137.8 <-> 192.168.137.1)
#   - Bearer 3: Stationary Bluetooth PAN "bt-pan" (192.168.44.8 <-> 192.168.44.1)

sleep 8
setprop service.adb.tcp.port 5555
setprop persist.adb.tcp.port 5555
settings put global adb_wifi_enabled 1
settings put global stay_on_while_plugged_in 7
settings put global wifi_sleep_policy 2
settings put global tether_dun_required 0
svc power stayon true
svc wifi enable
echo act_omega_shiba_compute > /sys/power/wake_lock 2>/dev/null

# Start Rooted Pixel 8 Apex Daemon (:8098 Speculative Drafter + :8097 Headless Telemetry Streamer)
if [ -x /data/local/tmp/p8_ksu_apex_daemon ]; then
    /data/local/tmp/p8_ksu_apex_daemon --daemon
fi

# Background watchdog: maintain GARLOCK00 0975 Wi-Fi 6 Hotspot (192.168.137.8/24),
# Bluetooth PAN (bt-pan 192.168.44.8/24), kernel routing tables, and p8_ksu_apex_daemon
(
    while true; do
        echo act_omega_shiba_compute > /sys/power/wake_lock 2>/dev/null

        # 1. Ensure Wi-Fi 6 Direct Hotspot ("GARLOCK00 0975") association & routing
        if ! ip addr show wlan0 2>/dev/null | grep -q "192.168.137.8"; then
            cmd wifi connect-network 4741524c4f434b30302030393735 wpa2 '011e9^2X' -x >/dev/null 2>&1
            sleep 2
            ip addr add 192.168.137.8/24 dev wlan0 2>/dev/null || ip addr replace 192.168.137.8/24 dev wlan0 2>/dev/null
        fi
        ip route replace 192.168.137.0/24 dev wlan0 src 192.168.137.8 table local_network 2>/dev/null
        ip route replace 192.168.137.0/24 dev wlan0 src 192.168.137.8 table wlan0 2>/dev/null
        ip route replace default via 192.168.137.1 dev wlan0 table wlan0 2>/dev/null
        ip rule show | grep -q "to 192.168.137.0/24 lookup local_network" || ip rule add to 192.168.137.0/24 lookup local_network pref 1000 2>/dev/null
        iptables -C INPUT -s 192.168.137.0/24 -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -s 192.168.137.0/24 -j ACCEPT 2>/dev/null
        iptables -C OUTPUT -d 192.168.137.0/24 -j ACCEPT 2>/dev/null || iptables -I OUTPUT 1 -d 192.168.137.0/24 -j ACCEPT 2>/dev/null

        # 2. Ensure Stationary Bluetooth PAN (bt-pan -> 192.168.44.8/24) routing when interface is up
        if ip link show bt-pan >/dev/null 2>&1; then
            ip link set bt-pan up 2>/dev/null
            if ! ip addr show bt-pan 2>/dev/null | grep -q "192.168.44.8"; then
                ip addr add 192.168.44.8/24 dev bt-pan 2>/dev/null || ip addr replace 192.168.44.8/24 dev bt-pan 2>/dev/null
            fi
            ip route replace 192.168.44.0/24 dev bt-pan src 192.168.44.8 table local_network 2>/dev/null
            ip rule show | grep -q "to 192.168.44.0/24 lookup local_network" || ip rule add to 192.168.44.0/24 lookup local_network pref 1010 2>/dev/null
            iptables -C INPUT -s 192.168.44.0/24 -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -s 192.168.44.0/24 -j ACCEPT 2>/dev/null
            iptables -C OUTPUT -d 192.168.44.0/24 -j ACCEPT 2>/dev/null || iptables -I OUTPUT 1 -d 192.168.44.0/24 -j ACCEPT 2>/dev/null
        fi

        # 3. Ensure p8_ksu_apex_daemon (:8098 + :8097 streamer) is alive
        if [ -x /data/local/tmp/p8_ksu_apex_daemon ]; then
            if ! kill -0 $(cat /data/local/tmp/p8_ksu_apex.pid 2>/dev/null) 2>/dev/null; then
                /data/local/tmp/p8_ksu_apex_daemon --daemon
            fi
        fi

        sleep 15
    done
) &
