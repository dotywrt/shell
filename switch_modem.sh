#!/bin/sh
# Simple ModemManager-based modem switcher
# Usage:
#   /root/switch_modem.sh qmi
#   /root/switch_modem.sh mbim
#   /root/switch_modem.sh ppp

MODE="$1"
APN="internet"

if [ -z "$MODE" ]; then
  echo "Usage: $0 [qmi|mbim|ppp]"
  exit 1
fi

echo "Updating package list..."
opkg update >/dev/null 2>&1
opkg install modemmanager luci-proto-modemmanager usbutils >/dev/null 2>&1

echo "Restarting ModemManager..."
/etc/init.d/modemmanager restart
sleep 3

MODEM=$(mmcli -L 2>/dev/null | grep -o '/org/freedesktop/ModemManager1/Modem/[0-9]*' | head -n1)

if [ -z "$MODEM" ]; then
  echo "No modem detected. Please check USB connection."
  exit 1
fi

echo "Detected modem: $MODEM"

case "$MODE" in
  qmi)
    echo "Switching to QMI mode..."
    mmcli -m $MODEM --set-preferred-mode='lte'
    mmcli -m $MODEM --set-allowed-modes='4g'
    mmcli -m $MODEM --set-preferred-bearer='lte'
    ;;
  mbim)
    echo "Switching to MBIM mode..."
    mmcli -m $MODEM --set-preferred-mode='lte'
    mmcli -m $MODEM --set-allowed-modes='4g'
    ;;
  ppp)
    echo "Switching to PPP mode..."
    mmcli -m $MODEM --set-allowed-modes='3g'
    ;;
  *)
    echo "Invalid mode. Use: qmi | mbim | ppp"
    exit 1
    ;;
esac

echo "Connecting with APN: $APN"
mmcli -m $MODEM --simple-connect="apn=$APN" || {
  echo "Failed to connect."
  exit 1
}

echo "Connection established."
mmcli -m $MODEM --bearer | grep -E "status|interface"
