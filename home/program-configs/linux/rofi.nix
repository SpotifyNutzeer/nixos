{ dotfiles, ... }:
{
  # Eigenes (angepasstes) Catppuccin-Theme verbatim aus den dotfiles ziehen.
  # NICHT catppuccin.rofi nutzen — das wäre das Standard-Theme.
  xdg.configFile."rofi".source = "${dotfiles}/.config/rofi";
}
