#!/bin/bash

# --- OSIRIS RGB UNIVERSAL INSTALLER ---
# Target: Acer 516 GE (Osiris)
# Description: Compiles ectool, sets up 4-zone mapping, and configures boot/wake automation.

echo "Starting Osiris RGB Setup..."

# 1. Install Build Dependencies
echo "Installing dependencies..."
sudo apt update
sudo apt install -y build-essential cmake libftdi1-dev libusb-1.0-0-dev git

# 2. Clone and Build ectool (DHowett version)
# We build from source to ensure protocol compatibility with Osiris firmware
echo "Building ectool from source..."
if [ -d "ectool" ]; then rm -rf ectool; fi
git clone https://github.com/DHowett/ectool.git
cd ectool && mkdir build && cd build
cmake .. && make

# Install the binary to a system-wide path
sudo cp ectool /usr/local/bin/ectool
sudo chmod +x /usr/local/bin/ectool
cd ../.. # Return to original directory

# 3. Create the 'rainbow' command script
# This script targets the specific hardware anchors 1, 5, 9, and 12
echo "Creating /usr/local/bin/rainbow..."
cat << 'EOF' | sudo tee /usr/local/bin/rainbow
#!/bin/bash
# Ensure the kernel module for Chromebook EC is loaded
modprobe cros_ec_lpcs 2>/dev/null

# Disable hardware demo mode so manual colors work
/usr/local/bin/ectool rgbkbd demo 0

# Set keyboard backlight brightness to 100%
/usr/local/bin/ectool pwmsetkblight 100

# Apply the 4-Zone Gradient via Daisy-Chain Anchors
# Zone 1 (Left): Red
/usr/local/bin/ectool rgbkbd 1 16711680
# Zone 2 (Mid-Left): Yellow
/usr/local/bin/ectool rgbkbd 5 16776960
# Zone 3 (Mid-Right): Green
/usr/local/bin/ectool rgbkbd 9 65280
# Zone 4 (Far Right): Blue
/usr/local/bin/ectool rgbkbd 12 255
EOF

# Make the rainbow script executable
sudo chmod +x /usr/local/bin/rainbow

# 4. Create Systemd Service for Boot Automation
# This ensures the keyboard lights up before login
echo "Configuring boot-time automation..."
cat << 'EOF' | sudo tee /etc/systemd/system/keyboard-rgb.service
[Unit]
Description=Set Keyboard RGB Rainbow at Boot
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/rainbow
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service so it runs on every boot
sudo systemctl daemon-reload
sudo systemctl enable keyboard-rgb.service

# 5. Create Resume Hook for Wake-from-Sleep
# This ensures the keyboard relights after closing/opening the lid
echo "Configuring wake-from-sleep hook..."
cat << 'EOF' | sudo tee /usr/lib/systemd/system-sleep/rainbow-resume
#!/bin/sh
case $1 in
  post)
    /usr/local/bin/rainbow
    ;;
esac
EOF

# Make the resume hook executable
sudo chmod +x /usr/lib/systemd/system-sleep/rainbow-resume

echo "--------------------------------------------------------"
echo "SETUP COMPLETE!"
echo "--------------------------------------------------------"
echo "1. Run 'rainbow' to activate the effect now."
echo "2. Use 'sudo ectool rgbkbd 0 0' to turn lights off."
echo "3. Use 'sudo ectool rgbkbd demo 1' for animated rainbow."
echo ""
echo "Your keyboard will now automatically set the rainbow on boot and wake."
