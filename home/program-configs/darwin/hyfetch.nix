{ config, pkgs, ... }:
{
  # hyfetch ist (in nixpkgs) ein Rust-Binary und sucht seine Config via dirs-Crate
  # auf macOS in ~/Library/Application Support/hyfetch.json — NICHT in ~/.config,
  # wohin programs.hyfetch (shared/hyfetch.nix) sie schreibt. Auf Linux mappt dirs
  # auf ~/.config, daher geht es dort. Hier denselben generierten JSON zusaetzlich
  # auf den macOS-Pfad verlinken (DRY, kein zweiter Settings-Block).
  home.file."Library/Application Support/hyfetch.json".source =
    config.xdg.configFile."hyfetch.json".source;

  # backend = "fastfetch" braucht das fastfetch-Binary. Auf NixOS liefert es
  # common/programs.nix system-weit; auf darwin fehlt es -> hier bereitstellen.
  home.packages = [ pkgs.fastfetch ];
}
