{ pkgs, ... }:
let
  # DaVinci Resolve does not decode AAC audio on Linux, and AV1 video is a
  # delivery codec (long-GOP, hard to decode, Resolve support shaky).
  # That is why we transcode after the standard Resolve ingest: video -> DNxHR
  # HQ (8-bit 4:2:2), audio -> PCM (pcm_s16le), into a .mov container. That is
  # guaranteed to import and scrubs smoothly.
  #
  # The AV1 decode runs via NVDEC on the GPU (-hwaccel cuda), the frames are
  # then pulled into RAM for the CPU DNxHR encoder (NVENC cannot do DNxHR).
  # For codecs without NVDEC support ffmpeg automatically falls back to
  # software decoding.
  #
  # Progress: ffmpeg writes machine-readable values via -progress; an awk
  # filter renders a bar with percent, speed and ETA from them (ETA from the
  # remaining duration / current speed). Automatically falls back to ffmpeg's
  # default output when not writing to a terminal.
  resolve-reencode = pkgs.writeShellScriptBin "resolve-reencode" ''
    set -u
    FF=${pkgs.ffmpeg}/bin/ffmpeg
    FP=${pkgs.ffmpeg}/bin/ffprobe

    if [ "$#" -eq 0 ]; then
      echo "Usage: resolve-reencode <video> [<video>...]" >&2
      echo "" >&2
      echo "Transcodes video to DNxHR HQ and audio to PCM (s16le) into a" >&2
      echo ".mov container so that DaVinci Resolve can import the file." >&2
      echo "Output: <name>_resolve.mov" >&2
      exit 1
    fi

    count=$#
    idx=0
    status=0
    for src in "$@"; do
      idx=$((idx + 1))
      if [ ! -f "$src" ]; then
        printf '\033[31m✗ not found:\033[0m %s\n' "$src" >&2
        status=1
        continue
      fi

      dir=$(dirname -- "$src")
      base=$(basename -- "$src")
      stem=''${base%.*}
      out="$dir/''${stem}_resolve.mov"
      outbase=$(basename -- "$out")

      # Total duration (in microseconds) for percent + ETA.
      dur=$("$FP" -v error -show_entries format=duration \
              -of default=nk=1:nw=1 -- "$src" 2>/dev/null || true)
      dur_us=$(awk -v d="$dur" 'BEGIN { printf "%d", (d == "" || d == "N/A") ? 0 : d * 1000000 }')

      printf '\033[1m[%d/%d]\033[0m %s \033[2m→\033[0m %s\n' "$idx" "$count" "$base" "$outbase" >&2

      if [ -t 2 ]; then
        # Progress pipeline: -progress on stdout, awk draws the bar on stderr.
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
                  # Without a known duration, only show elapsed time + speed.
                  printf "\r\033[2K  %s processed  \033[36m%s\033[0m", hms(t / 1000000), spdstr > "/dev/stderr"
                }
                if (done) printf "\n" > "/dev/stderr"
                fflush()
              }
            '
        rc=''${PIPESTATUS[0]}
      else
        # Non-terminal (log/pipe): ffmpeg's default status line.
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
        printf '\033[31m✗ ffmpeg failed (rc=%s) for\033[0m %s\n\n' "$rc" "$src" >&2
        status=1
      fi
    done
    exit "$status"
  '';
in
{
  environment.systemPackages = [ resolve-reencode ];
}
