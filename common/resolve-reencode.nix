{ pkgs, ... }:
let
  # DaVinci Resolve dekodiert unter Linux kein AAC-Audio, und AV1-Video ist ein
  # Delivery-Codec (Long-GOP, schwer zu dekodieren, Resolve-Support wackelig).
  # Darum wird nach dem Standard-Resolve-Ingest transkodiert: Video -> DNxHR HQ
  # (8-bit 4:2:2), Audio -> PCM (pcm_s16le), in einen .mov-Container. Das
  # importiert garantiert und scrubbt fluessig.
  resolve-reencode = pkgs.writeShellScriptBin "resolve-reencode" ''
    set -eu
    if [ "$#" -eq 0 ]; then
      echo "Usage: resolve-reencode <video> [<video>...]" >&2
      echo "" >&2
      echo "Transkodiert Video nach DNxHR HQ und Audio nach PCM (s16le) in einem" >&2
      echo ".mov-Container, damit DaVinci Resolve die Datei importieren kann." >&2
      echo "Ausgabe: <name>_resolve.mov" >&2
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
          -map 0:v:0 -map 0:a? \
          -c:v dnxhd -profile:v dnxhr_hq -pix_fmt yuv422p \
          -c:a pcm_s16le \
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
