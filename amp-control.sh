#!/bin/bash

# Configuration
GPIO=14

# PulseAudio sink names (from `pactl list sinks short`)
SINK1="alsa_output.platform-fe00b840.mailbox.stereo-fallback"
SINK2="alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.analog-stereo"
ENABLE_SINK2=true

AMP_STATE="off"

# Setup GPIO as output and turn off amp
pigs m $GPIO w
pigs w $GPIO 0

turn_on_amp() {
    pigs w $GPIO 1
    AMP_STATE="on"
    echo "[amp-control] Amp ON"
}

turn_off_amp() {
    pigs w $GPIO 0
    AMP_STATE="off"
    echo "[amp-control] Amp OFF"
}

get_sink_state() {
    local sink="$1"
    local current_state=""
    local current_sink=""

    while IFS= read -r line; do
        # Trim leading whitespace
        line="${line#"${line%%[![:space:]]*}"}"

        if [[ "$line" =~ ^State:\ (.+)$ ]]; then
            current_state="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^Name:\ (.+)$ ]]; then
            current_sink="${BASH_REMATCH[1]}"
            if [[ "$current_sink" == "$sink" ]]; then
                echo "$current_state"
                return 0
            fi
        fi
    done < <(pactl list sinks)
}

update_amp_state() {
    local state1 state2
    state1=$(get_sink_state "$SINK1")

    if [[ "$ENABLE_SINK2" == "true" ]]; then
        state2=$(get_sink_state "$SINK2")
    else
        state2="$state1"
    fi

    if [[ "$state1" == "RUNNING" || "$state2" == "RUNNING" || "$state1" == "IDLE" || "$state2" == "IDLE" ]]; then
        if [[ "$AMP_STATE" == "off" ]]; then
            turn_on_amp
        fi
    elif [[ "$state1" == "SUSPENDED" && "$state2" == "SUSPENDED" ]]; then
        if [[ "$AMP_STATE" == "on" ]]; then
            turn_off_amp
        fi
    fi
}

update_amp_state
# Monitor PulseAudio sink changes
pactl subscribe | while read -r line; do
    if echo "$line" | grep -q "Event 'change' on sink"; then
        update_amp_state
    fi
done

