#!/bin/bash
set -euo pipefail

TERMINAL="${TERMINAL:-kitty}"

have() { command -v "$1" >/dev/null 2>&1; }

# ---- Audio helpers -------------------------------------------------
vol_up() {
  if have wpctl; then wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.0
  elif have pactl; then pactl set-sink-volume @DEFAULT_SINK@ +5%
  elif have amixer; then amixer set Master 5%+
  fi
}
vol_down() {
  if have wpctl; then wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
  elif have pactl; then pactl set-sink-volume @DEFAULT_SINK@ -5%
  elif have amixer; then amixer set Master 5%-
  fi
}
vol_toggle_mute() {
  if have wpctl; then wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
  elif have pactl; then pactl set-sink-mute @DEFAULT_SINK@ toggle
  elif have amixer; then amixer set Master toggle
  fi
}
pick_sink() {
  if have pactl; then
    sel="$(pactl list short sinks | awk '{print $1"  "$2"  "$3}' | wofi --dmenu --prompt 'Sinks')" || exit 0
    id="$(printf "%s" "$sel" | awk '{print $1}')"
    [ -n "${id:-}" ] && pactl set-default-sink "$id" && \
      pactl list short sink-inputs | awk '{print $1}' | xargs -r -n1 pactl move-sink-input "$id"
  elif have wpctl; then
    sel="$(wpctl status | awk '/Sinks:/{flag=1;next}/Sources:/{flag=0}flag' | sed 's/^[[:space:]]*//;s/.*\. //;' | nl -w2 -s'  ' | wofi --dmenu --prompt 'Sinks')" || exit 0
    num="$(printf "%s" "$sel" | awk '{print $1}')"
    # Cette partie dépend des noms exacts ; ajuste si besoin
    [ -n "${num:-}" ] && wpctl set-default "alsa_output.$((num-1))" 2>/dev/null || true
  else
    notify-send "Audio" "Ni wpctl ni pactl trouvés."
  fi
}

# ---- Menu principal ------------------------------------------------
main_choice=$(printf "%s\n" \
  "  Réseau" \
  "  Bluetooth" \
  "  Énergie" \
  "  Session" \
  "  Écran" \
  "  Son" \
  "  Langue" \
  "󰈸  Custom" \
  | wofi --dmenu --prompt "Centre de contrôle")

case "$main_choice" in
  *"Réseau")
    net_choice=$(printf "%s\n" \
      "  Wi-Fi (nmtui)" \
      "  Interfaces réseau (ip a)" \
      "  Ping 8.8.8.8" \
      | wofi --dmenu --prompt "Réseau")
    case "$net_choice" in
      *"Wi-Fi (nmtui)")           "$TERMINAL" -e nmtui ;;
      *"Interfaces réseau"*)      "$TERMINAL" -e bash -lc 'ip a; read -p "Entrée pour quitter..."' ;;
      *"Ping 8.8.8.8")            "$TERMINAL" -e bash -lc 'ping 8.8.8.8; read -p "Entrée pour quitter..."' ;;
    esac
    ;;

  *"Bluetooth")
    bt_choice=$(printf "%s\n" \
      "󰂯  Bluetuith (gestion)" \
      "󰂲  État du service (systemctl)" \
      | wofi --dmenu --prompt "Bluetooth")
    case "$bt_choice" in
      *"Bluetuith"*)              "$TERMINAL" -e /home/solenopsis/go/bin/bluetuith ;;
      *"État du service"*)        "$TERMINAL" -e bash -lc 'systemctl status bluetooth; read -p "Entrée pour quitter..."' ;;
    esac
    ;;

  *"Énergie")
    power_choice=$(printf "%s\n" \
      "  Mettre en veille" \
      "  Éteindre" \
      "  Redémarrer" \
      "  Verrouiller (swaylock)" \
      | wofi --dmenu --prompt "Énergie")
    case "$power_choice" in
      *"veille")                  systemctl suspend ;;
      *"Éteindre")                systemctl poweroff ;;
      *"Redémarrer")              systemctl reboot ;;
      *"Verrouiller"*)            swaylock ;;
    esac
    ;;

  *"Session")
    session_choice=$(printf "%s\n" \
      "󰗽  Logout (Quitter Sway)" \
      "  Recharger la config Sway" \
      "  Moniteur système (btop)" \
      | wofi --dmenu --prompt "Session")
    case "$session_choice" in
      *"Logout")                  swaymsg exit ;;
      *"Recharger la config"*)    swaymsg reload ;;
      *"Moniteur système"*)       "$TERMINAL" -e btop ;;
    esac
    ;;

  *"Écran")
    display_choice=$(printf "%s\n" \
      "  Wdisplays" \
      "󰍹  Sorties (swaymsg)" \
      | wofi --dmenu --prompt "Écran")
    case "$display_choice" in
      *"Wdisplays")               wdisplays ;;
      *"swaymsg")                 "$TERMINAL" -e bash -lc 'swaymsg -t get_outputs; read -p "Entrée pour quitter..."' ;;
    esac
    ;;

  *"Son")
    sound_choice=$(printf "%s\n" \
      "  Volume +5%" \
      "  Volume −5%" \
      "  Mute / Unmute" \
      "󰓃  Sélectionner la sortie (sink)" \
      "󰕾  Ouvrir pavucontrol" \
      | wofi --dmenu --prompt "Son")
    case "$sound_choice" in
      *"Volume +")                vol_up ;;
      *"Volume −"*)               vol_down ;;
      *"Mute"*)                   vol_toggle_mute ;;
      *"Sélectionner la sortie"*) pick_sink ;;
      *"pavucontrol")             pavucontrol & ;;
    esac
    ;;

  *"Langue")
    lang_choice=$(printf "%s\n" \
      "󰊸  Français (fr)" \
      "󰧮  Anglais US (us)" \
      "󰻂  Espagnol (es)" \
      | wofi --dmenu --prompt "Langue clavier")
    case "$lang_choice" in
      *"(fr)")                    swaymsg input type:keyboard xkb_layout fr ;;
      *"(us)")                    swaymsg input type:keyboard xkb_layout us ;;
      *"(es)")                    swaymsg input type:keyboard xkb_layout es ;;
    esac
    ;;

*"Custom")
    CUSTOM_FILE="$HOME/.config/sway/scripts/CUSTOM"

    if [ ! -f "$CUSTOM_FILE" ]; then
    notify-send "Control Center" "Aucun fichier CUSTOM trouvé à $CUSTOM_FILE"
    exit 0
    fi

    # Construire la liste des noms à afficher
    choices=$(awk -F'\t' '{print $1}' "$CUSTOM_FILE" | sed '/^$/d')
    # Si les noms ne sont pas séparés par des tabulations, on récupère tout avant le dernier espace
    if [ -z "$choices" ]; then
    choices=$(awk '{$NF=""; print $0}' "$CUSTOM_FILE" | sed '/^$/d')
    fi

    custom_choice=$(printf "%s\n" "$choices" | wofi --dmenu --prompt "Custom") || exit 0

    # Récupérer le chemin du script associé
    script_path=$(grep -F "$custom_choice" "$CUSTOM_FILE" | awk '{print $NF}')

    if [ -z "$script_path" ]; then
    notify-send "Control Center" "Aucun script trouvé pour '$custom_choice'"
    exit 1
    fi

    # Exécution
    if [ -x "$script_path" ]; then
    "$script_path" &
    else
    "$TERMINAL" -e bash -lc "$script_path" &
    fi
    ;;

esac
