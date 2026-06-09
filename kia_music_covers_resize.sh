#!/bin/bash

INPUT="$1"
OUTPUT="$2"

if [ -z "$INPUT" ] || [ -z "$OUTPUT" ]; then
  echo "Użycie: ./kia_prepare.sh <plik_lub_folder> <folder_wyjsciowy>"
  exit 1
fi

mkdir -p "$OUTPUT"

# Sprawdzenie zależności
command -v ffmpeg >/dev/null 2>&1 || { echo "Brakuje ffmpeg (brew install ffmpeg)"; exit 1; }
command -v id3v2 >/dev/null 2>&1 || { echo "Brakuje id3v2 (brew install id3v2)"; exit 1; }

process_file() {
  FILE="$1"
  BASENAME=$(basename "$FILE")
  OUTFILE="$OUTPUT/$BASENAME"

  echo "→ Obrabiam: $BASENAME"

  # 1) Wyciągnięcie okładki (dowolny format: JPG/PNG)
  ffmpeg -y -i "$FILE" -an -vcodec copy cover_tmp 2>/dev/null

  # Jeśli ffmpeg zapisał okładkę bez rozszerzenia, wykryj format
  if [ -f cover_tmp ]; then
    FILETYPE=$(file --mime-type -b cover_tmp)
    case "$FILETYPE" in
      image/jpeg) mv cover_tmp cover_tmp.jpg ;;
      image/png) mv cover_tmp cover_tmp.png ;;
      *) rm -f cover_tmp ;;
    esac
  fi

  # 2) Konwersja PNG → JPG + zmiana rozmiaru
  if [ -f cover_tmp.png ]; then
    ffmpeg -y -i cover_tmp.png -vf scale=500:500 cover_fixed.jpg 2>/dev/null
  elif [ -f cover_tmp.jpg ]; then
    ffmpeg -y -i cover_tmp.jpg -vf scale=500:500 cover_fixed.jpg 2>/dev/null
  fi

  # 3) Kopia pliku
  cp "$FILE" "$OUTFILE"

  # 4) Usunięcie starych tagów
  id3v2 -D "$OUTFILE"

  # 5) Dodanie okładki i zapis w ID3v2.3
  if [ -f cover_fixed.jpg ]; then
    id3v2 --APIC cover_fixed.jpg "$OUTFILE"
  fi

  # 6) Wymuszenie ID3v2.3
  id3v2 -2 "$OUTFILE"

  rm -f cover_tmp.jpg cover_tmp.png cover_fixed.jpg
}

# Jeśli INPUT jest plikiem
if [ -f "$INPUT" ]; then
  process_file "$INPUT"
  echo "✔ Gotowe! Plik zapisany w: $OUTPUT"
  exit 0
fi

# Jeśli INPUT jest folderem
if [ -d "$INPUT" ]; then
  find "$INPUT" -type f \( -iname "*.mp3" -o -iname "*.flac" \) | while read FILE; do
    process_file "$FILE"
  done

  echo "✔ Gotowe! Pliki zapisane w: $OUTPUT"
  exit 0
fi

echo "Błąd: $INPUT nie jest ani plikiem, ani folderem"
exit 1