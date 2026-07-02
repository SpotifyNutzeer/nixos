{ ... }:
{
  programs.fish = {
    enable = true;
    # Completions aus Man-Pages generieren (für Tools ohne eigene Fish-Completions)
    generateCompletions = true;
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
