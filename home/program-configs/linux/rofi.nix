{ dotfiles, ... }:
{
  # Pull the own (customized) Catppuccin theme verbatim from the dotfiles.
  # Do NOT use catppuccin.rofi - that would be the stock theme.
  xdg.configFile."rofi".source = "${dotfiles}/.config/rofi";
}
