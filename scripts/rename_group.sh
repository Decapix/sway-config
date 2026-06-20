#!/usr/bin/env bash
# Name (mark) the currently focused container so it shows up as [name] in the
# title bar via `show_marks yes`. Select the group first with $mod+a
# (focus parent) so the mark lands on the group, not a single window.
# Author: added for window-group management.
set -euo pipefail

name=$(printf '' | wofi --dmenu -p 'Nom du groupe' -W 320 -L 0) || exit 0
[ -z "$name" ] && exit 0

# `mark` (without --add) replaces any existing marks on the focused container.
swaymsg "mark \"$name\"" >/dev/null
