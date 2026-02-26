#!/usr/bin/env bash
set -euo pipefail

THRESHOLD=10
NAG_LOCK="/tmp/.battery_warn_lock"
UPOWER="/usr/bin/upower"
SWAYNAG="/usr/bin/swaynag"

BAT_DEV="$($UPOWER -e | grep -E 'BAT|battery' | head -n1 || true)"
[ -z "${BAT_DEV:-}" ] && exit 0

while :; do
  state="$($UPOWER -i "$BAT_DEV" | awk -F: '/state/{gsub(/^[ \t]+/,"",$2); print tolower($2); exit}')"
  percent="$($UPOWER -i "$BAT_DEV" | awk -F: '/percentage/{gsub(/[% \t]/,"",$2); print $2; exit}')"
  percent="${percent:-100}"

  if [[ "$state" == "charging" || "$state" == "fully-charged" ]]; then
    rm -f "$NAG_LOCK"
  elif [[ "$state" == "discharging" && "$percent" -le "$THRESHOLD" ]]; then
    if [[ ! -f "$NAG_LOCK" ]]; then
      "$SWAYNAG" -t warning -m "Batterie faible : ${percent}% !" -s "OK" -e top
      touch "$NAG_LOCK"
    fi
  fi

  sleep 60
done

