#!/usr/bin/env bash
# Flatten the focused workspace: pull every tiled window up to the workspace
# root (dissolving nested groups) and switch the workspace to a single tabbed
# layout. Handy when nested containers get confusing and you lose track.
# Author: added for window-group management.
set -euo pipefail

# Name of the currently focused workspace.
ws=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .name')
[ -z "$ws" ] && exit 0

tree=$(swaymsg -t get_tree)

# Remember the focused window so we can restore focus afterwards.
focused=$(echo "$tree" | jq -r 'recurse(.nodes[]?, .floating_nodes[]?)
  | select(.focused == true) | .id' | head -n1)

# All tiled leaf windows inside the focused workspace (floating left untouched).
ids=$(echo "$tree" | jq -r --arg ws "$ws" '
  recurse(.nodes[]?, .floating_nodes[]?)
  | select(.type == "workspace" and .name == $ws)
  | recurse(.nodes[]?)
  | select((.nodes | length) == 0 and .type == "con"
           and (.app_id != null or .window != null))
  | .id')

[ -z "$ids" ] && exit 0

# Re-parent each window to the workspace root. Emptied/single-child containers
# auto-collapse, which is what flattens the tree.
for id in $ids; do
    swaymsg "[con_id=$id] move container to workspace \"$ws\"" >/dev/null
done

# Single tabbed level, then restore the original focus.
swaymsg "workspace \"$ws\"; layout tabbed" >/dev/null
[ -n "$focused" ] && swaymsg "[con_id=$focused] focus" >/dev/null || true
