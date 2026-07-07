{ pkgs, ... }:
let
  # DaVinci Resolve dekodiert unter Linux kein AAC-Audio, und AV1-Video ist ein
  # Delivery-Codec (Long-GOP, schwer zu dekodieren, Resolve-Support wackelig).
  # Darum wird nach dem Standard-Resolve-Ingest transkodiert: Video -> DNxHR HQ
  # (8-bit 4:2:2), Audio -> PCM (pcm_s16le), in einen .mov-Container. Das
  # importiert garantiert und scrubbt fluessig.
  #
  # Der AV1-Decode laeuft per NVDEC auf der GPU (-hwaccel cuda), die Frames
  # werden dann fuer den CPU-DNxHR-Encoder in den RAM geholt (NVENC kann kein
  # DNxHR). Bei Codecs ohne NVDEC-Support faellt ffmpeg automatisch auf
  # Software-Decode zurueck.
  #
  # Fortschritt: ffmpeg schreibt maschinenlesbare Werte via -progress; ein
  # awk-Filter rendert daraus eine Bar mit Prozent, Speed und ETA (ETA aus der
  # Restdauer / aktuellem Speed). Faellt automatisch auf ffmpegs Standard-
  # Ausgabe zurueck, wenn nicht in ein Terminal geschrieben wird.
  resolve-reencode = pkgs.writeShellScriptBin "resolve-reencode" ''
    set -u
    FF=${pkgs.ffmpeg}/bin/ffmpeg
    FP=${pkgs.ffmpeg}/bin/ffprobe

    if [ "$#" -eq 0 ]; then
      echo "Usage: resolve-reencode <video> [<video>...]" >&2
      echo "" >&2
      echo "Transkodiert Video nach DNxHR HQ und Audio nach PCM (s16le) in einem" >&2
      echo ".mov-Container, damit DaVinci Resolve die Datei importieren kann." >&2
      echo "Ausgabe: <name>_resolve.mov" >&2
      exit 1
    fi

    count=$#
    idx=0
    status=0
    for src in "$@"; do
      idx=$((idx + 1))
      if [ ! -f "$src" ]; then
        printf '\033[31m✗ nicht gefunden:\033[0m %s\n' "$src" >&2
        status=1
        continue
      fi

      dir=$(dirname -- "$src")
      base=$(basename -- "$src")
      stem=''${base%.*}
      out="$dir/''${stem}_resolve.mov"
      outbase=$(basename -- "$out")

      # Gesamtdauer (in Mikrosekunden) fuer Prozent + ETA.
      dur=$("$FP" -v error -show_entries format=duration \
              -of default=nk=1:nw=1 -- "$src" 2>/dev/null || true)
      dur_us=$(awk -v d="$dur" 'BEGIN { printf "%d", (d == "" || d == "N/A") ? 0 : d * 1000000 }')

      printf '\033[1m[%d/%d]\033[0m %s \033[2m→\033[0m %s\n' "$idx" "$count" "$base" "$outbase" >&2

      if [ -t 2 ]; then
        # Fortschritts-Pipeline: -progress auf stdout, awk zeichnet die Bar auf stderr.
        "$FF" -hide_banner -loglevel error -nostats -progress pipe:1 \
            -hwaccel cuda -i "$src" \
            -map 0:v:0 -map 0:a? \
            -c:v dnxhd -profile:v dnxhr_hq -pix_fmt yuv422p \
            -c:a pcm_s16le \
            -y "$out" \
          | awk -v dur="$dur_us" -v W=36 '
              function hms(s,   h, m) {
                if (s < 0) s = 0
                h = int(s / 3600); s -= h * 3600
                m = int(s / 60);   s = int(s - m * 60)
                return h > 0 ? sprintf("%d:%02d:%02d", h, m, s) : sprintf("%02d:%02d", m, s)
              }
              /^out_time_us=/ { split($0, a, "="); t = a[2] + 0 }
              /^fps=/         { split($0, a, "="); fps = a[2] + 0 }
              /^speed=/       { v = $0; sub(/^speed=/, "", v); sub(/x$/, "", v); spd = (v == "N/A") ? 0 : v + 0 }
              /^progress=/ {
                done = ($0 ~ /end/)
                if (done && dur > 0) t = dur
                spdstr = (spd > 0) ? sprintf("%.2fx", spd) : "—"
                if (dur > 0) {
                  pct = t / dur * 100; if (pct > 100) pct = 100
                  fill = int(pct / 100 * W)
                  bar = ""
                  for (i = 0; i < fill; i++) bar = bar "█"
                  for (i = fill; i < W;    i++) bar = bar "░"
                  eta = (spd > 0) ? (dur - t) / 1000000 / spd : -1
                  etastr = (eta >= 0) ? hms(eta) : "—"
                  printf "\r\033[2K\033[32m%s\033[0m %5.1f%%  \033[36m%7s\033[0m  ETA \033[33m%s\033[0m", bar, pct, spdstr, etastr > "/dev/stderr"
                } else {
                  # Ohne bekannte Dauer nur verstrichene Zeit + Speed zeigen.
                  printf "\r\033[2K  %s verarbeitet  \033[36m%s\033[0m", hms(t / 1000000), spdstr > "/dev/stderr"
                }
                if (done) printf "\n" > "/dev/stderr"
                fflush()
              }
            '
        rc=''${PIPESTATUS[0]}
      else
        # Nicht-Terminal (Log/Pipe): ffmpegs Standard-Statuszeile.
        "$FF" -hide_banner -hwaccel cuda -i "$src" \
            -map 0:v:0 -map 0:a? \
            -c:v dnxhd -profile:v dnxhr_hq -pix_fmt yuv422p \
            -c:a pcm_s16le \
            -y "$out"
        rc=$?
      fi

      if [ "$rc" -eq 0 ]; then
        sz=$(du -h -- "$out" 2>/dev/null | cut -f1)
        printf '\033[32m✓\033[0m %s \033[2m(%s)\033[0m\n\n' "$outbase" "$sz" >&2
      else
        printf '\033[31m✗ ffmpeg fehlgeschlagen (rc=%s) fuer\033[0m %s\n\n' "$rc" "$src" >&2
        status=1
      fi
    done
    exit "$status"
  '';
in
{
  environment.systemPackages = [ resolve-reencode ];
}
