#!/bin/bash

# Keyboard input name
keyboard_input_name="1:1:AT_Translated_Set_2_keyboard"

# Date and time
date_and_week=$(date "+%d/%m/%Y")
current_time=$(date "+%H:%M")

# Battery
battery_charge=$(upower --show-info $(upower --enumerate | grep 'BAT') | egrep "percentage" | awk '{print $2}')
battery_status=$(upower --show-info $(upower --enumerate | grep 'BAT') | egrep "state" | awk '{print $2}')

# Network
network=$(ip route get 1.1.1.1 | grep -Po '(?<=dev\s)\w+' | cut -f1 -d ' ')
interface_easyname=$(dmesg | grep $network | grep renamed | awk 'NF>1{print $NF}')
ping=$(ping -c 1 www.google.es | tail -1| awk '{print $4}' | cut -d '/' -f 2 | cut -d '.' -f 1)

# Language and memory
language=$(swaymsg -r -t get_inputs | awk '/1:1:AT_Translated_Set_2_keyboard/;/xkb_active_layout_name/' | grep -A1 '\b1:1:AT_Translated_Set_2_keyboard\b' | grep "xkb_active_layout_name" | awk -F '"' '{print $4}')
mem_used=$(free | awk '/Mem:/ {printf("%.2f%%\n", $3/$2 * 100)}')
mem_percent=$(free | awk '/Mem:/ {print $3/$2 * 100}')

# Icons with color tags
#arch_icon=""  # Bleu
language_icon="⌨"
network_icon=""
no_network_icon="󰖪"
memory_icon="󰍛"
battery_full_icon="󰁹"
battery_charging_icon="󰂄"
calendar_icon=""
clock_icon=""

#arch_icon="\033[34m\033[0m"  # Bleu via ANSI

#memory_warning="\033[31m󰍛 $mem_used\033[0m"  # Rouge si <10%

# Battery icon
if [ "$battery_status" = "discharging" ]; then
    battery_pluggedin="$battery_full_icon"
else
    battery_pluggedin="$battery_charging_icon"
fi

# Network icon
if ! [ "$network" ]; then
    network_active="$no_network_icon"
else
    network_active="$network_icon"
fi

memory_display="$memory_icon  $mem_used"

# Final output
echo "$language_icon $language  |  $network_active $interface_easyname  ($ping ms)  |  $memory_display  |  $battery_pluggedin  $battery_charge  |  $calendar_icon  $date_and_week  $clock_icon  $current_time"
