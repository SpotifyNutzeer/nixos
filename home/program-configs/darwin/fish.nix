{ ... }:
{
  # fish-Login-Shell auf macOS: zwei PATH-Probleme, beide hier in loginShellInit
  # gefixt (laeuft nach dem macOS-path_helper):
  #
  # 1) nix-darwin-systemPath (/run/current-system/sw/bin + per-user home-manager-
  #    Profil) fehlt: macOS `path_helper` (via /etc/zprofile) baut den PATH aus
  #    /etc/paths* neu auf und wirft die nix-Pfade raus; das gesetzte
  #    __NIX_DARWIN_SET_ENVIRONMENT_DONE=1 verhindert die erneute Injektion durch
  #    nixos-env-preinit. Daher die Profile-Pfade hier explizit wieder voranstellen
  #    -> hyfetch/fzf/carapace & alle home-manager-User-Pakete sind erreichbar.
  #
  # 2) Homebrew wird von nix-darwin nicht automatisch in den PATH gelegt.
  programs.fish.loginShellInit = ''
    for p in /run/current-system/sw/bin /etc/profiles/per-user/$USER/bin
      test -d $p; and fish_add_path --global --prepend $p
    end

    if test -x /opt/homebrew/bin/brew
      /opt/homebrew/bin/brew shellenv fish | source
    end
  '';
}
