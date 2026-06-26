{ ... }:
{
  programs.fish = {
    enable = true;
  };

  home.sessionPath = [ "$HOME/.local/bin" ];
  
  home.sessionVariables = {
    DOCKER_HOST = "unix:///run/user/1000/docker.sock";
  };
}
