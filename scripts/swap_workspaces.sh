#!/bin/bash

ws1="$1"
ws2="$2"

# Déplacer toutes les fenêtres du workspace 1 vers le workspace 2
swaymsg "[workspace=$ws1] move workspace to output current"
swaymsg "[workspace=$ws1] move to workspace $ws2"

ls
# Déplacer toutes les fenêtres du workspace 2 vers le workspace 1
swaymsg "[workspace=$ws2] move workspace to output current"
swaymsg "[workspace=$ws2] move to workspace $ws1"

# Aller vers l'un des espaces de travail (par exemple, workspace 1)
swaymsg "workspace $ws1"

