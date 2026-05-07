#!/bin/bash

GPIO=14
ENABLE_SINK2=false
DEBOUNCE_SECONDS=10

SINK1_NAME="ReSpeaker Lite"
SINK2_NAME="USB Audio Device"

AMP_STATE="off"

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
    local name="$1"

    pw-dump | jq -r --arg NAME "$name" '
        .[] 
        | select(.type == "PipeWire:Interface:Node")
        | select(.info.props["media.class"] == "Audio/Sink")
        | select(.info.props["alsa.card_name"] == $NAME)
        | .info.state
    ' | head -n1
}

update_amp_state() {
    local s1 s2

    s1=$(get_sink_state "$SINK1_NAME")

    if [[ "$ENABLE_SINK2" == "true" ]]; then
        s2=$(get_sink_state "$SINK2_NAME")
    else
        s2="$s1"
    fi

    # Normalize empty → not running
    [[ -z "$s1" ]] && s1="suspended"
    [[ -z "$s2" ]] && s2="suspended"
    echo S1: $s1 S2: $s2

    if [[ "$s1" == "running" || "$s2" == "running" ]]; then
	echo should turn on
        [[ "$AMP_STATE" == "off" ]] && turn_on_amp
        return
    fi

    if [[ "$AMP_STATE" == "on" ]]; then
            if [[ "$s1" == "suspended" && "$s2" == "suspended" ]]; then
                turn_off_amp
            fi
    fi
}

# ---- main loop ----

while true; do
    update_amp_state
    sleep 2
done
