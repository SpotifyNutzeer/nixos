{ pkgs, ... }:
let
  # DaVinci Resolve dekodiert unter Linux kein AAC-Audio (gilt auch fuer
  # Studio – es ist eine Audio-Limitierung der Linux-Version, unabhaengig von
  # der Lizenz). H.264/H.265-Video kann Resolve Studio dagegen. Darum wird nur
  # die Tonspur nach PCM (pcm_s16le) umgewandelt, das Video 1:1 kopiert und in
  # einen .mov-Container (PCM-freundlich, Resolve-nativ) gemuxt.
  resolve-reencode = pkgs.writeShellScriptBin "resolve-reencode" ''
    set -eu
    if [ "$#" -eq 0 ]; then
      echo "Usage: resolve-reencode <video> [<video>...]" >&2
      echo "" >&2
      echo "Wandelt AAC-Audio nach PCM (s16le) in einem .mov-Container um," >&2
      echo "damit DaVinci Resolve die Datei importieren kann." >&2
      echo "Das Video wird unveraendert kopiert. Ausgabe: <name>_resolve.mov" >&2
      exit 1
    fi

    status=0
    for src in "$@"; do
      if [ ! -f "$src" ]; then
        echo "resolve-reencode: Datei nicht gefunden: $src" >&2
        status=1
        continue
      fi

      dir=$(dirname -- "$src")
      base=$(basename -- "$src")
      stem=''${base%.*}
      out="$dir/''${stem}_resolve.mov"

      echo ">> $src -> $out"
      if ${pkgs.ffmpeg}/bin/ffmpeg -hide_banner -i "$src" \
          -map 0:v -map 0:a? \
          -c:v copy -c:a pcm_s16le \
          "$out"; then
        :
      else
        echo "resolve-reencode: ffmpeg fehlgeschlagen fuer $src" >&2
        status=1
      fi
    done
    exit "$status"
  '';
in
{
  environment.systemPackages = [ resolve-reencode ];
}
