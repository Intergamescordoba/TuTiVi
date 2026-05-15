# TuTiVi

**TuTiVi** convierte una PC Linux en una TV Box ligera controlable desde el celular mediante KDE Connect.

La idea es simple:

```text
Copias una URL en el celular
↓
KDE Connect sincroniza el portapapeles con la PC
↓
Ejecutas “Abrir en TuTiVi”
↓
La PC reproduce el video en pantalla completa con mpv

TuTiVi usa herramientas libres como mpv, yt-dlp, KDE Connect, socat, xclip y ffmpeg.

Estado del proyecto

Versión actual:

TuTiVi 0.1 Alpha
Esta versión ya permite:

reproducir URLs
agregar videos a cola
controlar reproducción desde KDE Connect
mostrar títulos en pantalla
usar controles multimedia nativos mediante MPRIS
leer URLs desde el portapapeles
funcionar por SSH o desde comandos remotos
Características principales
Reproduce videos desde URLs compatibles con yt-dlp.
Usa mpv como reproductor.
Control por socket IPC.
Cola de reproducción.
OSD en pantalla con título del video.
Integración con KDE Connect.
Control multimedia nativo mediante MPRIS.
Lectura de URL desde portapapeles con xclip.
Instalador básico para Linux.
No modifica el handler global de enlaces HTTP/HTTPS.
No depende del archivo personal ~/.config/mpv/mpv.conf.
Dependencias

El instalador intenta instalar automáticamente:

mpv
socat
python3
curl
xclip
kdeconnect
ffmpeg
mpv-mpris

Además instala/actualiza yt-dlp como binario local en:

~/.local/bin/yt-dlp
Instalación

Clona o copia la carpeta del proyecto:

cd ~/TuTiVi
./install.sh

El instalador crea:

~/.config/tutivi/

e instala comandos globales en:

/usr/local/bin/tutivi
/usr/local/bin/enlazador-tutivi
/usr/local/bin/abrir-tutivi
/usr/local/bin/tutivi-handler
Configuración

El archivo principal de configuración queda en:

~/.config/tutivi/tutivi.conf

Valores importantes:

TUTIVI_NAME="TuTiVi"
MPV_SOCKET="/tmp/tutivi-mpv-socket"
DISPLAY_ID=":0"
DOWNLOAD_DIR="$HOME/Downloads/TuTiVi"

En sistemas usados por SSH o KDE Connect, normalmente DISPLAY_ID=":0" es necesario para que el video se abra en la pantalla física de la PC.

Uso básico

Abrir un video:

tutivi abrir "https://www.youtube.com/watch?v=..."

Agregar un video a la cola:

tutivi agregar "https://www.youtube.com/watch?v=..."

Pausar o reanudar:

tutivi pausa

Pasar al siguiente video:

tutivi siguiente

Mostrar título en pantalla:

tutivi titulo

Mostrar título actual en terminal:

tutivi actual

Detener TuTiVi:

tutivi detener

Ver estado:

tutivi estado
Uso con KDE Connect
Flujo recomendado
1. Copia una URL en el celular.
2. KDE Connect sincroniza el portapapeles con la PC.
3. Ejecuta el comando “Abrir en TuTiVi”.
4. TuTiVi abre el video o lo agrega a la cola.
Comando recomendado en KDE Connect

En KDE Connect crea un comando llamado:

Abrir en TuTiVi

Comando:

/usr/local/bin/abrir-tutivi

Este comando lee la URL desde el portapapeles de la PC usando xclip.

Control multimedia desde KDE Connect

TuTiVi carga mpv-mpris si está disponible.

Esto permite que KDE Connect muestre:

reproducir / pausar
siguiente
anterior
miniatura
título del video
control multimedia nativo

Esto evita tener que crear muchos comandos manuales en KDE Connect.

Por qué TuTiVi no usa handler global HTTP/HTTPS por defecto

TuTiVi no se registra automáticamente como handler global de enlaces web.

No modifica:

x-scheme-handler/http
x-scheme-handler/https

Esto evita interferir con:

navegador
correo
links de verificación
links bancarios
formularios
notificaciones
recuperación de contraseña

El modo recomendado es usar KDE Connect + portapapeles.

Comandos instalados
tutivi

Comando principal.

enlazador-tutivi

Recibe una URL como argumento o la lee desde el portapapeles.

abrir-tutivi

Wrapper recomendado para KDE Connect.

tutivi-handler

Handler interno usado por el enlazador.

Prueba rápida
echo "https://www.youtube.com/watch?v=7QU1nvuxaMA" | xclip -selection clipboard
abrir-tutivi

Debe abrir el video en pantalla completa.

Para agregar otro video a la cola:

echo "https://www.youtube.com/watch?v=QK4sLI1U7Ic" | xclip -selection clipboard
abrir-tutivi
Solución de problemas
El video solo reproduce audio

Probablemente falta DISPLAY.

Revisa:

echo $DISPLAY

TuTiVi usa:

DISPLAY_ID=":0"

en:

~/.config/tutivi/tutivi.conf
KDE Connect ejecuta el comando pero no abre video

Usa el wrapper:

/usr/local/bin/abrir-tutivi

No uses solo:

enlazador-tutivi

porque KDE Connect puede ejecutar comandos con un entorno reducido.

El portapapeles no se sincroniza

Verifica que KDE Connect tenga activada la sincronización de portapapeles.

Prueba en la PC:

xclip -selection clipboard -o

Después de copiar una URL en el celular.

mpv no se cierra

Usa:

tutivi detener

TuTiVi intenta cerrar el reproductor por socket y, si es necesario, limpia solo procesos mpv iniciados por TuTiVi.

yt-dlp no se encuentra

Verifica:

command -v yt-dlp
yt-dlp --version

Debe existir:

~/.local/bin/yt-dlp

Si no está en el PATH, agrega a ~/.bashrc:

export PATH="$HOME/.local/bin:$PATH"
Filosofía

TuTiVi busca ser:

ligero
simple
controlable desde celular
no invasivo
compatible con Linux
útil para miniPCs o PCs recicladas

La meta no es reemplazar Kodi, Plex o VLC.

La meta es convertir una PC Linux en una TV Box práctica, sencilla y controlada desde el celular.

Autor
Arturo B.
Proyecto creado desde Intergames Córdoba.