#!/bin/bash

# ══════════════════════════════════════════════════════════════
#  TuTiVi Installer
# ══════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════"
echo "           TuTiVi 0.1 Installer"
echo "                By Arturo B                    "
echo "═══════════════════════════════════════════════"
echo ""

INSTALL_DIR="$HOME/.config/tutivi"

echo "[1/5] Creando directorios..."

mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/history"
mkdir -p "$INSTALL_DIR/downloads"
mkdir -p "$INSTALL_DIR/logs"
mkdir -p "$INSTALL_DIR/mpv"

echo "[2/5] Copiando configuración..."

cp config/tutivi.conf.example \
    "$INSTALL_DIR/tutivi.conf"

echo "[3/5] Copiando configuración mpv..."

cp mpv/mpv.conf \
    "$INSTALL_DIR/mpv/mpv.conf"

echo "[4/5] Instalando core..."

cp -r core "$INSTALL_DIR/"

echo "[5/5] Instalando comando global..."

sudo ln -sf "$(pwd)/tutivi" /usr/local/bin/tutivi
sudo ln -sf "$(pwd)/handlers/tutivi-handler" /usr/local/bin/tutivi-handler


chmod +x tutivi
chmod +x handlers/tutivi-handler
chmod +x core/functions.sh

echo ""
echo "✅ TuTiVi instalado correctamente."
echo ""
echo "Usa por ejemplo:"
echo ""
echo "   tutivi play https://www.youtube.com/watch?v=7QU1nvuxaMA"
echo ""
echo "        Desarrollado por Intergames Còrdoba v.0.01"