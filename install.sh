#!/bin/bash

# Variables
VENDOR_ID="1395"
PRODUCT_ID="00a0"
UDEV_RULES_FILE="/etc/udev/rules.d/99-sennheiser-gsx.rules"
ALSA_PROFILE_SETS_DIR="/usr/share/alsa-card-profile/mixer/profile-sets"
SENNHEISER_GSX_FILE="sennheiser-gsx.conf"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CONF_DIR="$SCRIPT_DIR/conf"

check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please enter your password to continue."
    exec sudo "$0"
    exit
  fi
}
check_root

# Configuration file
if [ ! -f "$ALSA_PROFILE_SETS_DIR/$SENNHEISER_GSX_FILE" ]; then
  echo "sennheiser.gsx not found in $ALSA_PROFILE_SETS_DIR."

  if [ -f "$CONF_DIR/$SENNHEISER_GSX_FILE" ]; then
    echo "Copying sennheiser.gsx from $CONF_DIR to $ALSA_PROFILE_SETS_DIR..."
    cp "$CONF_DIR/$SENNHEISER_GSX_FILE" "$ALSA_PROFILE_SETS_DIR/"

    if [ -f "$ALSA_PROFILE_SETS_DIR/$SENNHEISER_GSX_FILE" ]; then
      echo "sennheiser.gsx copied successfully."
    else
      echo "Failed to copy sennheiser.gsx. Please check permissions."
      exit 1
    fi
  else
    echo "sennheiser.gsx not found in $CONF_DIR. Please ensure the file exists in the conf folder."
    exit 1
  fi
else
  echo "sennheiser.gsx already exists in $ALSA_PROFILE_SETS_DIR."
fi

# Create the udev rule
echo "Creating udev rule to disable input functionality for Sennheiser GSX 1000..."
cat <<EOF | tee "$UDEV_RULES_FILE" >/dev/null
ACTION=="add", SUBSYSTEM=="input", ATTRS{idVendor}=="$VENDOR_ID", ATTRS{idProduct}=="$PRODUCT_ID", ENV{ID_INPUT}="0"
EOF

if [ -f "$UDEV_RULES_FILE" ]; then
  echo "Udev rule created successfully at $UDEV_RULES_FILE."
else
  echo "Failed to create udev rule. Please check permissions."
  exit 1
fi

echo "Reloading udev rules..."
udevadm control --reload-rules

if [ $? -eq 0 ]; then
  echo "Udev rules reloaded successfully."
else
  echo "Failed to reload udev rules."
  exit 1
fi

# Notify the user to reconnect the device
echo "Please unplug and reconnect your Sennheiser GSX 1000 device for the changes to take effect."
