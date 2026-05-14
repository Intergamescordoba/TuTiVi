#!/bin/bash

# ══════════════════════════════════════════════════════════════
#  TuTiVi Core Functions
# ══════════════════════════════════════════════════════════════

# Ruta base de configuración
CONFIG_DIR="$HOME/.config/tutivi"

# Cargar configuración
if [[ -f "$CONFIG_DIR/tutivi.conf" ]]; then
    source "$CONFIG_DIR/tutivi.conf"
else
    source "$(dirname "${BASH_SOURCE[0]}")/../config/tutivi.conf.example"
fi

# ══════════════════════════════════════════════════════════════
#  Verificar si mpv está corriendo
# ══════════════════════════════════════════════════════════════

_tutivi_running() {
    [[ -S "$MPV_SOCKET" ]] && pgrep mpv > /dev/null
}

# ══════════════════════════════════════════════════════════════
#  Enviar comando a mpv IPC
# ══════════════════════════════════════════════════════════════

_tutivi_cmd() {
    echo "$1" | socat - "$MPV_SOCKET" 2>/dev/null
}

# ══════════════════════════════════════════════════════════════
#  OSD en pantalla usando mpv
# ══════════════════════════════════════════════════════════════

_tutivi_osd() {

    local MESSAGE="$1"
    local DURATION="${2:-$OSD_DURATION}"

    [[ ! -S "$MPV_SOCKET" ]] && return 0

    echo '{"command":["show-text","'"$MESSAGE"'","'"$DURATION"'"]}' \
        | socat - "$MPV_SOCKET" 2>/dev/null
}

# ══════════════════════════════════════════════════════════════
#  Notificación KDE Connect
# ══════════════════════════════════════════════════════════════

_tutivi_notify() {

    local MESSAGE="$1"

    [[ -z "$KDECONNECT_DEVICE" ]] && return 0

    kdeconnect-cli -d "$KDECONNECT_DEVICE" \
        --ping-msg "$MESSAGE" >/dev/null 2>&1
}

# ══════════════════════════════════════════════════════════════
#  Parsear URL
# ══════════════════════════════════════════════════════════════

_tutivi_parse_url() {

    local INPUT="$1"

    local re_shorts='shorts/([a-zA-Z0-9_-]+)'
    local re_video='[?&]v=([a-zA-Z0-9_-]+)'
    local re_id='^[a-zA-Z0-9_-]{11}$'

    if [[ "$INPUT" =~ $re_shorts ]]; then

        echo "https://youtube.com/watch?v=${BASH_REMATCH[1]}"

    elif [[ "$INPUT" =~ $re_video ]]; then

        echo "https://youtube.com/watch?v=${BASH_REMATCH[1]}"

    elif [[ "$INPUT" =~ $re_id ]]; then

        echo "https://youtube.com/watch?v=$INPUT"

    elif [[ "$INPUT" =~ ^https?:// ]]; then

        echo "$INPUT"

    else

        echo ""

    fi
}