{ pkgs, catppuccin, ... }:
{
  imports = [ catppuccin.nixosModules.catppuccin ];

  # X11-Greeter: auf NVIDIA zuverlässig. Macht die Session NICHT zu X11 —
  # Hyprland startet weiterhin als Wayland-Session; X ist nur fürs Login-Fenster.
  services.xserver.enable = true;

  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;   # Qt6 – vom Catppuccin-Theme verlangt
  };
  services.displayManager.defaultSession = "hyprland";

  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
    accent = "teal";
    sddm.enable = true;
  };
}
