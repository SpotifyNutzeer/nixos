{ ... }:
{
  # Homebrew in den fish-PATH bringen. nix-darwin macht das NICHT automatisch,
  # und ohne das ist weder `brew` selbst noch ein brew-installiertes Tool (htop,
  # …) in der fish-Login-Shell erreichbar. Voller Pfad, da brew sonst nicht im
  # PATH ist; `shellenv fish` gibt fish-Syntax aus und setzt PATH + HOMEBREW_*.
  programs.fish.loginShellInit = ''
    if test -x /opt/homebrew/bin/brew
      /opt/homebrew/bin/brew shellenv fish | source
    end
  '';
}
