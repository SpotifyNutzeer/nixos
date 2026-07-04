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
  services.displayManager.defaultSession = "hyprland-uwsm";

  # gnome-keyring als Secret-Service (org.freedesktop.secrets), beim Login
  # automatisch mit dem Login-Passwort entsperren. tidal-hifi
  # (--password-store=gnome-libsecret) braucht das, sonst fragt TidaLuna bei
  # jedem Start neu nach Plugin-Permissions.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # gnome-keyring aktiviert per Default auch gcr-ssh-agent. Der hat unter Hyprland
  # aber keinen funktionierenden Passphrase-Prompt (kein gnome-shell/gcr-prompter),
  # dadurch hängt jede SSH-Signatur (git clone/push blockiert bei "Cloning into...").
  # Secret-Service (org.freedesktop.secrets) für tidal bleibt aktiv – nur der
  # SSH-Teil wird abgeschaltet. Den SSH-Agent übernimmt home-manager
  # (services.ssh-agent) in home/program-configs/ssh.nix.
  services.gnome.gcr-ssh-agent.enable = false;

  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
    accent = "teal";
    sddm.enable = true;
  };
}
