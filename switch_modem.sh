#!/bin/sh
# Usage:
#   /root/switch_modem.sh qmi
#   /root/switch_modem.sh mbim
#   /root/switch_modem.sh ppp

MODE="$1"

if [ -z "$MODE" ]; then
  echo "Usage: $0 [qmi|mbim|ppp]"
  exit 1
fi

echo "Checking required packages..."
opkg update >/dev/null 2>&1
opkg install modemmanager usb-modeswitch usbutils >/dev/null 2>&1

echo "Restarting ModemManager..."
/etc/init.d/modemmanager restart
sleep 3

MODEM=$(mmcli -L 2>/dev/null | grep -o '/org/freedesktop/ModemManager1/Modem/[0-9]*' | head -n1)

if [ -z "$MODEM" ]; then
  echo "Error: No modem detected. Please check USB connection."
  exit 1
fi

echo "Detected modem: $MODEM"

RESULT=1
case "$MODE" in
  qmi)
    echo "Switching to QMI mode..."
    mmcli -m "$MODEM" --set-primary-port-type=qmi 2>/dev/null
    mmcli -m "$MODEM" --set-device-mode='qmi' 2>/dev/null
    RESULT=$?
    ;;
  mbim)
    echo "Switching to MBIM mode..."
    mmcli -m "$MODEM" --set-primary-port-type=mbim 2>/dev/null
    mmcli -m "$MODEM" --set-device-mode='mbim' 2>/dev/null
    RESULT=$?
    ;;
  ppp)
    echo "Switching to PPP mode..."
    mmcli -m "$MODEM" --set-primary-port-type=at 2>/dev/null
    mmcli -m "$MODEM" --set-device-mode='ppp' 2>/dev/null
    RESULT=$?
    ;;
  *)
    echo "Invalid mode. Use: qmi | mbim | ppp"
    exit 1
    ;;
esac

if [ "$RESULT" -eq 0 ]; then
  echo "Mode switch command sent successfully."
  echo "Verifying mode..."
  sleep 2
  mmcli -m "$MODEM" | grep -E "primary port type|device|bearer" | sed 's/^/  /'
  echo "Done. You may need to replug the modem for the change to take effect."
else
  echo "Mode switch failed or not supported by this modem."
  echo "Please ensure the modem supports $MODE mode."
  exit 1
fi
