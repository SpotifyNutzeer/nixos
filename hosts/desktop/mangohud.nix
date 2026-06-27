{ dotfiles, ... }:
{
  # MangoHud-Config verbatim aus den dotfiles (blacklist=gamescope etc.).
  xdg.configFile."MangoHud/MangoHud.conf".source =
    "${dotfiles}/.config/MangoHud/MangoHud.conf";
}
