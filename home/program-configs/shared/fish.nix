{ ... }:
{
  programs.fish = {
    enable = true;
    # Completions aus Man-Pages generieren (für Tools ohne eigene Fish-Completions)
    generateCompletions = true;
    # Startup-Übersicht: hyfetch (teal-sky-Module aus fastfetch.nix) nur im
    # ersten interaktiven Fish pro Terminal-Fenster — nested Shells und
    # tmux-Splits erben __greeting_shown und bleiben ruhig.
    interactiveShellInit = ''
      set -g fish_greeting
      if not set -q __greeting_shown
          set -gx __greeting_shown 1
          command -q hyfetch; and hyfetch
      end
    '';
    shellAliases = {
      grep = "rg";
      ls = "eza -la --group-directories-first --icons";
      cat = "bat";
    };
  };

  # Completions für hunderte CLIs (git, docker, kubectl, nix, ...) inkl. Beschreibungen
  programs.carapace = {
    enable = true;
    enableFishIntegration = true;
  };

  # Fuzzy-Finder: Ctrl+R = fuzzy History, Ctrl+T = Dateien, Alt+C = cd
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  home.sessionPath = [ "$HOME/.local/bin" ];
  
  home.sessionVariables = {
    DOCKER_HOST = "unix:///run/user/1000/docker.sock";
  };
}
