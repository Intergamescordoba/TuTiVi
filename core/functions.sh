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
#  Comprobacion de arranque limpio en MPV 
# ══════════════════════════════════════════════════════════════

_tutivi_running() {
    _tutivi_socket_alive && _tutivi_has_media
}

_tutivi_socket_alive() {
    [[ -S "$MPV_SOCKET" ]] && \
    echo '{"command":["get_property","pid"]}' \
        | socat - "$MPV_SOCKET" >/dev/null 2>&1
}

_tutivi_current_path() {
    [[ ! -S "$MPV_SOCKET" ]] && return 1

    echo '{"command":["get_property","path"]}' \
        | socat - "$MPV_SOCKET" 2>/dev/null \
        | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    data = d.get("data", "")
    print(data if data else "")
except Exception:
    print("")
'
}

_tutivi_has_media() {
    local CURRENT
    CURRENT=$(_tutivi_current_path)

    [[ -n "$CURRENT" && "$CURRENT" != "?" && "$CURRENT" != "null" ]]
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

    python3 - "$MESSAGE" "$DURATION" "$MPV_SOCKET" >/dev/null 2>&1 <<'PY'
import sys
import json
import socket

message = sys.argv[1]
duration = int(sys.argv[2])
socket_path = sys.argv[3]

payload = {
    "command": ["show-text", message, duration]
}

data = json.dumps(payload).encode("utf-8") + b"\n"

try:
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.settimeout(1)
    sock.connect(socket_path)
    sock.sendall(data)

    try:
        sock.recv(4096)
    except Exception:
        pass

    sock.close()

except Exception:
    pass
PY
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

# ══════════════════════════════════════════════════════════════
#  Iniciar mpv
# ══════════════════════════════════════════════════════════════

_tutivi_start_mpv() {

    local URL="$1"

    rm -f "$MPV_SOCKET"

    DISPLAY="$DISPLAY_ID" mpv --no-config --fs \
        --input-ipc-server="$MPV_SOCKET" \
        --osd-playing-msg-duration=5000 \
        --osd-font-size=40 \
        --osd-align-x=center \
        --osd-align-y=bottom \
        --osd-margin-y=80 \
        --ytdl-format="bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720]" \
        "$URL" >/dev/null 2>&1 &
}

# ══════════════════════════════════════════════════════════════
#  Mostrar titulo mientras se reproduce el video
# ══════════════════════════════════════════════════════════════

_tutivi_title_osd() {
    local VIDEO_TITLE

    VIDEO_TITLE=$(
        _tutivi_cmd '{"command":["get_property","media-title"]}' | \
        python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    title = d.get("data", "")
    print(title.strip() if isinstance(title, str) else "")
except Exception:
    print("")
'
    )

    if [[ -n "$VIDEO_TITLE" \
       && "$VIDEO_TITLE" != "?" \
       && "$VIDEO_TITLE" != "title" \
       && "$VIDEO_TITLE" != *"watch?v="* \
       && "$VIDEO_TITLE" != http://* \
       && "$VIDEO_TITLE" != https://* ]]; then

        _tutivi_osd $'TuTiVi Player:\n'"$VIDEO_TITLE" 5000
    else
        _tutivi_osd "TuTiVi Player - Sin título" 5000
    fi
}