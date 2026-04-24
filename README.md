# Acer 516 GE (Osiris) RGB Keyboard Linux Controller
Script to get rainbow effect on keyboard of Acer 516 GE (Osiris) Chromebook running Ubuntu 26.04

## Installation Instructions
Copy the entire block below and paste it into your terminal. This creates a local installation script, makes it executable, and runs it to set up the drivers, rainbow script, and boot automation.

```bash
cat << 'EOF' > install_rgb.sh
#!/bin/bash
echo "Starting Osiris RGB Setup..."
sudo apt update
# Added pkg-config to the list below
sudo apt install -y build-essential cmake pkg-config libftdi1-dev libusb-1.0-0-dev git

echo "Building ectool from source..."
if [ -d "ectool" ]; then rm -rf ectool; fi
git clone https://github.com/DHowett/ectool.git
cd ectool

# FORCE OVERWRITE the first lines of CMakeLists.txt to satisfy modern CMake
echo "cmake_minimum_required(VERSION 3.10)" > CMakeLists.txt.new
echo "project(ectool C)" >> CMakeLists.txt.new
tail -n +3 CMakeLists.txt >> CMakeLists.txt.new
mv CMakeLists.txt.new CMakeLists.txt

mkdir build && cd build
cmake .. && make

# Note: Depending on the version of ectool, the binary might be in 'build/' or 'build/src/'
if [ -f "src/ectool" ]; then
    sudo cp src/ectool /usr/local/bin/ectool
elif [ -f "ectool" ]; then
    sudo cp ectool /usr/local/bin/ectool
else
    echo "ERROR: ectool binary not found."
    exit 1
fi

sudo chmod +x /usr/local/bin/ectool
echo "ectool built and installed successfully."
cd ../..

echo "Creating /usr/local/bin/rainbow..."
cat << 'OUTER_EOF' | sudo tee /usr/local/bin/rainbow
#!/bin/bash
# Ensure driver is loaded
modprobe cros_ec_lpcs 2>/dev/null
# All commands to the EC require sudo/root privileges
/usr/local/bin/ectool rgbkbd demo 0
/usr/local/bin/ectool pwmsetkblight 50
/usr/local/bin/ectool rgbkbd 1 16711680
/usr/local/bin/ectool rgbkbd 5 16776960
/usr/local/bin/ectool rgbkbd 9 65280
/usr/local/bin/ectool rgbkbd 12 255
OUTER_EOF
sudo chmod +x /usr/local/bin/rainbow

echo "Configuring boot-time automation..."
cat << 'OUTER_EOF' | sudo tee /etc/systemd/system/keyboard-rgb.service
[Unit]
Description=Set Keyboard RGB Rainbow at Boot
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/rainbow
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
OUTER_EOF

sudo systemctl daemon-reload
sudo systemctl enable keyboard-rgb.service

echo "Configuring wake-from-sleep hook..."
cat << 'OUTER_EOF' | sudo tee /usr/lib/systemd/system-sleep/rainbow-resume
#!/bin/sh
case $1 in
  post) /usr/local/bin/rainbow ;;
esac
OUTER_EOF
sudo chmod +x /usr/lib/systemd/system-sleep/rainbow-resume

echo "Installation Complete! Running rainbow with sudo..."
sudo /usr/local/bin/rainbow
EOF

chmod +x install_rgb.sh
./install_rgb.sh
```

## Technical Logic: How it Works

The Acer 516 GE uses a unique Embedded Controller (EC) mapping that differs from standard RGB keyboards:

* **Zone Interpolation:** The keyboard is wired in a daisy-chain. By targeting specific "anchor" IDs (**1, 5, 9, 12**), the hardware firmware automatically calculates a smooth color gradient between them.
* **The Global ID:** ID **0** is the "Master" index. Sending a color here overrides all zones for a solid look.
* **Decimal Color Math:** The hardware requires **24-bit Decimal Integers** rather than Hex. 
    * *Formula:* $(R \times 65536) + (G \times 256) + B$.
* **Priority Override:** Hardware-level animations (Demo Mode) take priority. Manual colors only work if `demo 0` is sent first.

## Why this `ectool` version?

Not all `ectool` binaries are equal. This setup compiles the source from **DHowett**, which is specifically compatible with the `rgbkbd` subcommands required for multi-zone Chromebook boards. Compiling locally prevents "Protocol Mismatch" errors found in generic pre-compiled binaries.

## Solid Color Reference
To set the **whole keyboard** to one color, use: `sudo ectool rgbkbd 0 [Value]`

| Color | Decimal Value | Command |
| :--- | :--- | :--- |
| **White** | `16777215` | `sudo ectool rgbkbd 0 16777215` |
| **Red** | `16711680` | `sudo ectool rgbkbd 0 16711680` |
| **Yellow** | `16776960` | `sudo ectool rgbkbd 0 16776960` |
| **Green** | `65280` | `sudo ectool rgbkbd 0 65280` |
| **Cyan** | `65535` | `sudo ectool rgbkbd 0 65535` |
| **Blue** | `255` | `sudo ectool rgbkbd 0 255` |
| **Magenta** | `16711935` | `sudo ectool rgbkbd 0 16711935` |
| **Off** | `0` | `sudo ectool rgbkbd 0 0` |


## Hardware Demo Modes

The Osiris firmware includes built-in animations that run at the hardware level. These are useful if you want dynamic effects without running a background script.

**Note:** Enabling a demo mode will override your static colors. You must run `sudo ectool rgbkbd demo 0` to return to your custom settings.

| Command | Effect |
| :--- | :--- |
| `sudo ectool rgbkbd demo 0` | **Disable Demos** (Required for static colors) |
| `sudo ectool rgbkbd demo 1` | **Cascading Rainbow** (Classic wave effect) |
| `sudo ectool rgbkbd demo 3` | **Breathing/Pulse** (Slow fade in/out) |
