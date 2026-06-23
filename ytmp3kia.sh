#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Użycie: ytmp3kia <link>"
  exit 1
fi

URL="$1"

echo "▶ Pobieram MP3 i miniaturę..."
yt-dlp -x --audio-format mp3 --write-thumbnail --convert-thumbnails jpg "$URL"

MP3=$(ls -t *.mp3 | head -n 1)
JPG=$(ls -t *.jpg | head -n 1)

echo "▶ MP3: $MP3"
echo "▶ JPG: $JPG"

echo "▶ Tworzę okładkę 500x500..."
ffmpeg -y -i "$JPG" -vf scale=500:500 cover.jpg

echo "▶ Usuwam MJPEG stream z MP3..."
ffmpeg -y -i "$MP3" -map 0:a -c copy clean.mp3

OUT="${MP3%.mp3}-KIA.mp3"
mv clean.mp3 "$OUT"

echo "▶ Otwieram Mp3tag — dodaj okładkę cover.jpg i zapisz plik"
open -a "Mp3tag" "$OUT"

echo "✔ GOTOWE: $OUT (otwarte w Mp3tag)"
