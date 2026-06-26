{ ... }:
{
  imports = [
    ./locale.nix
    ./users.nix
    ./environment.nix
    ./programs.nix
    ./desktop.nix
    ./nix.nix
  ];

  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };
  services.spice-vdagentd.enable = true;
}
