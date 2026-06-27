{ ... }:
{
  imports = [
    ./locale.nix
    ./users.nix
    ./environment.nix
    ./programs.nix
    ./desktop.nix
    ./nix.nix
    ./fonts.nix
    ./brave-policies.nix
  ];

  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };
  services.spice-vdagentd.enable = true;
}
