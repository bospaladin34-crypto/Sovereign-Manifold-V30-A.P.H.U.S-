#!/usr/bin/env bash
set -e
echo "=== [OMEGA R&D :: PIXEL 8 5.3GB AVF DEBIAN 13 PURE-COMPUTE NODE (:19793)] ==="
chmod go-w "$HOME" 2>/dev/null || true
mkdir -p "$HOME/.ssh" "$HOME/omega_p8_avf"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"

for keyf in /mnt/shared/Download/omega_rnd_ed25519.pub /mnt/shared/Download/linux/omega_rnd_ed25519.pub /mnt/shared/omega_rnd_ed25519.pub; do
  if [ -s "$keyf" ]; then
    PUBK="$(cat "$keyf" | tr -d '\r\n')"
    if [ -n "$PUBK" ]; then
      grep -Fq "$PUBK" "$HOME/.ssh/authorized_keys" 2>/dev/null || echo "$PUBK" >> "$HOME/.ssh/authorized_keys"
      if command -v sudo >/dev/null 2>&1; then
        sudo mkdir -p /root/.ssh && sudo chmod 700 /root/.ssh
        sudo touch /root/.ssh/authorized_keys
        sudo grep -Fq "$PUBK" /root/.ssh/authorized_keys 2>/dev/null || echo "$PUBK" | sudo tee -a /root/.ssh/authorized_keys >/dev/null
        sudo chmod 600 /root/.ssh/authorized_keys
      fi
    fi
    break
  fi
done

if ! command -v gcc >/dev/null 2>&1; then
  echo "[1/4] Installing gcc, libc6-dev, mesa-vulkan-drivers & openssh-server in 5.3GB Debian VM..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq gcc libc6-dev mesa-vulkan-drivers openssh-server
fi

if command -v sudo >/dev/null 2>&1 && [ -x /usr/sbin/sshd ]; then
  sudo mkdir -p /etc/ssh/sshd_config.d /run/sshd && sudo chmod 0755 /run/sshd
  printf 'Port 2222\nPubkeyAuthentication yes\nAuthorizedKeysFile .ssh/authorized_keys\nListenAddress 0.0.0.0\n' | sudo tee /etc/ssh/sshd_config.d/99-omegarnd.conf >/dev/null
  sudo ssh-keygen -A >/dev/null 2>&1 || true
  sudo systemctl restart ssh >/dev/null 2>&1 || sudo /usr/sbin/sshd -p 2222 >/dev/null 2>&1 || true
fi

SRC_FOUND=""
for sp in /mnt/shared/Download/omega_pocket_worker.c /mnt/shared/Download/linux/omega_pocket_worker.c /mnt/shared/omega_pocket_worker.c; do
  if [ -s "$sp" ]; then
    cp -f "$sp" "$HOME/omega_p8_avf/omega_pocket_worker.c"
    SRC_FOUND="$HOME/omega_p8_avf/omega_pocket_worker.c"
    break
  fi
done

if [ -z "$SRC_FOUND" ]; then
  echo "[ERROR] omega_pocket_worker.c not found in /mnt/shared/Download!"
  exit 1
fi

echo "[2/4] Compiling Stationary 9-vCPU ARMv9 I8MM (SMMLA) Work-Stealing Worker v2.0.0..."
cd "$HOME/omega_p8_avf"
(gcc -std=c11 -O3 -march=armv8.6-a+dotprod+i8mm+fp16 -pthread omega_pocket_worker.c -ldl -lm -o omega_p8_avf_worker.new 2>/dev/null \
 || gcc -std=c11 -O3 -march=armv8.2-a+dotprod -pthread omega_pocket_worker.c -ldl -lm -o omega_p8_avf_worker.new 2>/dev/null \
 || gcc -std=c11 -O3 -pthread omega_pocket_worker.c -ldl -lm -o omega_p8_avf_worker.new)
chmod 755 ./omega_p8_avf_worker.new
mv -f ./omega_p8_avf_worker.new ./omega_p8_avf_worker

echo "[3/4] Arming Persistent systemd Service omega-p8-avf-worker (:19793, --bind 0.0.0.0)..."
if command -v sudo >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
  printf '[Unit]\nDescription=Omega R&D Pixel 8 5.3GB AVF Debian 13 Pure-Compute Worker (:19793)\nAfter=network.target\n\n[Service]\nType=simple\nUser=%s\nWorkingDirectory=%s/omega_p8_avf\nExecStart=%s/omega_p8_avf/omega_p8_avf_worker --daemon --bind 0.0.0.0 --port 19793\nRestart=always\nRestartSec=2\n\n[Install]\nWantedBy=multi-user.target\n' "$(whoami)" "$HOME" "$HOME" | sudo tee /etc/systemd/system/omega-p8-avf-worker.service >/dev/null
  sudo systemctl daemon-reload
  sudo systemctl enable omega-p8-avf-worker.service >/dev/null 2>&1 || true
  sudo systemctl restart omega-p8-avf-worker.service
else
  killall -q omega_p8_avf_worker 2>/dev/null || true
  ./omega_p8_avf_worker --daemonize --bind 0.0.0.0 --port 19793
fi

sleep 0.6
echo "[4/4] Live 5.3GB AVF Worker (:19793) Telemetry:"
./omega_p8_avf_worker --port 19793 || true
echo "=== [PIXEL 8 5.3GB AVF DEBIAN VM LIVE ON :19793!] ==="
