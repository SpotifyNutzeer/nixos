{ catppuccin, ... }:
{
  imports = [ catppuccin.homeModules.catppuccin ];

  # Platform-independent Catppuccin base: themes all enabled CLI/TUI programs
  # via autoEnable (kitty, fish, starship, tmux, alacritty, fzf, bat). vim is
  # NOT auto-themed — it uses the catppuccin-vim plugin manually in vim.nix.
  # GTK/Qt/Kvantum/cursor are Linux concepts and live in linux/theming.nix.
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
    accent = "teal";
  };
}
