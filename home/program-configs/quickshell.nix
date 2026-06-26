{ dotfiles, ... }:
{
  xdg.configFile."quickshell".source = "${dotfiles}/.config/quickshell";
}
