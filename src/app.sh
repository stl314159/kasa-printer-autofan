#!/bin/bash

# Load environment variables from .env if the file exists
if [[ -f .env ]]; then
  source .env
fi

# Load environment variables from .env file
KASA_USERNAME=${KASA_USERNAME}
KASA_PASSWORD=${KASA_PASSWORD}
PRINTER_ALIAS=${PRINTER_ALIAS}
FAN_ALIAS=${FAN_ALIAS}
POWER_THRESHOLD=${POWER_THRESHOLD}

# Set timer for 5 minutes
TIMER=300
ITERATION_TIME=10

# Perform discovery
DEVICES=$(kasa --username $KASA_USERNAME --password $KASA_PASSWORD --json discover)

# Extract IP addresses and nicknames from devices
declare -a device_info
for ip in $(jq -r 'keys[]' <<< "$DEVICES"); do
  nickname_b64=$(jq -r ".\"$ip\".info.nickname" <<< "$DEVICES")
  nickname=$(echo "$nickname_b64" | base64 --decode)
  type=$(jq -r ".\"$ip\".info.type" <<< "$DEVICES")
  device_info+=("${ip}|${nickname}|${type}")
done

# Print extracted device info
echo "Extracted Device Info:"
echo "${device_info[@]}"

# Find the IP and type of the device with the nickname matching PRINTER_ALIAS
PRINTER_IP=""
PRINTER_TYPE=""
FAN_IP=""
FAN_TYPE=""
for device in "${device_info[@]}"; do
  IFS='|' read -r ip nickname type <<< "$device"
  # Debug: Print the current device being checked
  echo "Checking device: $nickname"
  if [[ "${PRINTER_ALIAS//\"/}" == "$nickname" ]]; then
    PRINTER_IP="$ip"
    PRINTER_TYPE="$type"
  elif [[ "${FAN_ALIAS//\"/}" == "$nickname" ]]; then
    FAN_IP="$ip"
    FAN_TYPE="$type"
    # Initialize fan state to the current state
    FAN_STATE=$(kasa --username $KASA_USERNAME --password $KASA_PASSWORD --host $FAN_IP --json sysinfo | jq -r '.device_on')
  fi
done

# Check if the printer and fan devices were found
if [[ -z "$PRINTER_IP" || -z "$FAN_IP" ]]; then
  echo "Printer or fan device not found."
  exit 1
fi

while true; do
  # Query the emeter level of the printer device
  EMETER_DATA=$(kasa --username $KASA_USERNAME --password $KASA_PASSWORD --host $PRINTER_IP --json emeter)
  POWER_MW=$(echo "$EMETER_DATA" | jq -r '.power_mw')

  # Debug: Print the current power level
  echo "Current power level: $POWER_MW mW"

  # Check if the power level is above the threshold
  if (( $(echo "$POWER_MW > $POWER_THRESHOLD" | bc -l) )); then
    # Check the current fan state
    FAN_STATE=$(kasa --username $KASA_USERNAME --password $KASA_PASSWORD --host $FAN_IP --json sysinfo | jq -r '.device_on')

    # Turn on the fan device if it's currently off
    if [[ "$FAN_STATE" == "false" ]]; then
      kasa --username $KASA_USERNAME --password $KASA_PASSWORD --host $FAN_IP --json on
      # Debug: Print the reason for turning on the fan
      echo "Power level exceeded threshold. Turning on the fan."
    fi
    POWER_BELOW_THRESHOLD_TIME=0
  else
    # Check if the power level has been below the threshold for at least 5 minutes
    POWER_BELOW_THRESHOLD_TIME=$((POWER_BELOW_THRESHOLD_TIME + ITERATION_TIME))
    # Debug: Print the current duration below the threshold
    echo "Power level below threshold for $POWER_BELOW_THRESHOLD_TIME seconds."
    if (( POWER_BELOW_THRESHOLD_TIME >= TIMER )); then
      # Check the current fan state
      FAN_STATE=$(kasa --username $KASA_USERNAME --password $KASA_PASSWORD --host $FAN_IP --json sysinfo | jq -r '.device_on')

      # Turn off the fan device if it's currently on
      if [[ "$FAN_STATE" == "true" ]]; then
        kasa --username $KASA_USERNAME --password $KASA_PASSWORD --host $FAN_IP --json off
        # Debug: Print the reason for turning off the fan
        echo "Power level below threshold for 5 minutes. Turning off the fan."
      fi
      POWER_BELOW_THRESHOLD_TIME=0
    fi
  fi

  LAST_POWER_LEVEL=$POWER_MW

  # Sleep for 1 second before checking again
  sleep $ITERATION_TIME
done