{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    dnsmasq
  ];
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  users.users.paul.extraGroups = [ "libvirtd" ];
}
