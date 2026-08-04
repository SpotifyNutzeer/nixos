{ dotfiles, ... }:
{
  # MangoHud config verbatim from the dotfiles (blacklist=gamescope etc.).
  xdg.configFile."MangoHud/MangoHud.conf".source =
    "${dotfiles}/.config/MangoHud/MangoHud.conf";
}
