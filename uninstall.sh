#!/bin/bash

# ══════════════════════════════════════════════════════════════
#  TuTiVi Uninstaller
# ══════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════"
echo "          TuTiVi Uninstaller"
echo "═══════════════════════════════════════════════"
echo ""

echo "Este script eliminará los comandos globales de TuTiVi."
echo ""

read -p "¿Deseas continuar? [s/N]: " CONFIRM

if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
    echo "Cancelado."
    exit 0
fi

echo ""
echo "[1/3] Deteniendo TuTiVi..."

if command -v tutivi >/dev/null 2>&1; then
    tutivi detener >/dev/null 2>&1
fi

echo "[2/3] Eliminando comandos globales..."

sudo rm -f /usr/local/bin/tutivi
sudo rm -f /usr/local/bin/tutivi-handler
sudo rm -f /usr/local/bin/enlazador-tutivi
sudo rm -f /usr/local/bin/abrir-tutivi

echo "[3/3] Configuración de usuario..."

read -p "¿Eliminar configuración de usuario en ~/.config/tutivi? [s/N]: " DELETE_CONFIG

if [[ "$DELETE_CONFIG" == "s" || "$DELETE_CONFIG" == "S" ]]; then
    rm -rf "$HOME/.config/tutivi"
    echo "Configuración eliminada."
else
    echo "Configuración conservada en ~/.config/tutivi"
fi

echo ""
echo "TuTiVi fue desinstalado."
echo ""
echo "Nota: no se eliminaron dependencias del sistema como mpv, ffmpeg, kdeconnect o xclip."
echo ""