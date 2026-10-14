# Google Antigravity Handoff Specification: Mobile Edge Telemetry Wire Contract

## 1. Network Endpoint
- Host Target: `127.0.0.1:8098` (via ADB reverse port forwarding `adb reverse tcp:8098 tcp:8098`) or Wi-Fi LAN IP.
- Protocol: Raw TCP binary stream.

## 2. Packet Binary Schema (64 Bytes Fixed, Little-Endian)
- Offset 0..7 (8 bytes, u64): `seq` sequence counter.
- Offset 8..19 (12 bytes, [f32; 3]): Geomagnetic field vector [Bx, By, Bz] in uT.
- Offset 20..23 (4 bytes, f32): Field norm ||B|| in uT.
- Offset 24..27 (4 bytes, f32): Carrier phase angle in radians.
- Offset 28..31 (4 bytes, f32): Carrier clock frequency (15.0 Hz).
- Offset 32..47 (16 bytes, [f32; 4]): Attitude quaternion [qw, qx, qy, qz].
- Offset 48 (1 byte, u8): Regime ID (1 = Nominal, 2 = AFE Transition).
- Offset 49..63 (15 bytes, [u8; 15]): Zero-padding to align to 64 bytes.

## 3. Streaming Heartbeat
- Cadence: ~16.0 Hz (~62.5 ms per frame).