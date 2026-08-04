{ config, ... }:
{
  # hyfetch is (in nixpkgs) a Rust binary and looks for its config via the dirs
  # crate on macOS in ~/Library/Application Support/hyfetch.json - NOT in ~/.config,
  # where programs.hyfetch (shared/hyfetch.nix) writes it. On Linux, dirs maps to
  # ~/.config, hence it works there. Here, additionally link the same generated
  # JSON to the macOS path (DRY, no second settings block).
  home.file."Library/Application Support/hyfetch.json".source =
    config.xdg.configFile."hyfetch.json".source;
}
