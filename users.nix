{ pkgs, ... }:
{
  users.users."paul" = {
    isNormalUser = true;
    description = "Paul Reitmayer";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    shell = pkgs.fish;
  };
}
