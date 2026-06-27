{ dotfiles, ... }:
{
  xdg.configFile."pipewire/pipewire.conf.d".source =
    "${dotfiles}/.config/pipewire/pipewire.conf.d";
}
