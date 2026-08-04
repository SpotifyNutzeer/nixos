{ ... }:
{
  # fish login shell on macOS: two PATH problems, both fixed here in loginShellInit
  # (runs after the macOS path_helper):
  #
  # 1) nix-darwin systemPath (/run/current-system/sw/bin + per-user home-manager
  #    profile) is missing: macOS `path_helper` (via /etc/zprofile) rebuilds the
  #    PATH from /etc/paths* and throws out the nix paths; the already-set
  #    __NIX_DARWIN_SET_ENVIRONMENT_DONE=1 prevents re-injection by
  #    nixos-env-preinit. Therefore explicitly prepend the profile paths again here
  #    -> hyfetch/fzf/carapace & all home-manager user packages are reachable.
  #
  # 2) Homebrew is not put on the PATH automatically by nix-darwin.
  programs.fish.loginShellInit = ''
    for p in /run/current-system/sw/bin /etc/profiles/per-user/$USER/bin
      test -d $p; and fish_add_path --global --prepend $p
    end

    if test -x /opt/homebrew/bin/brew
      /opt/homebrew/bin/brew shellenv fish | source
    end
  '';
}
