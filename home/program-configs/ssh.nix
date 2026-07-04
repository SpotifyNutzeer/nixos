{ pkgs, ... }:
let
  # Askpass-Helfer: liest die Key-Passphrase aus dem gnome-keyring
  # (org.freedesktop.secrets). So kann der Key beim Login automatisch und ohne
  # Tippen in den Agent geladen werden. Die Passphrase liegt dabei NICHT im
  # Nix-Store/Repo, sondern im keyring (siehe secret-tool-Befehl unten).
  keyringAskpass = pkgs.writeShellScript "ssh-askpass-keyring" ''
    exec ${pkgs.libsecret}/bin/secret-tool lookup ssh id_ed25519
  '';
in
{
  # secret-tool zum einmaligen Ablegen/Auslesen der Passphrase
  home.packages = [ pkgs.libsecret ];

  programs.ssh = {
    enable = true;
    # eigene Defaults statt der (deprecateten) home-manager-Vorgaben
    enableDefaultConfig = false;

    settings = {
      # Keys beim ersten Benutzen automatisch in den Agent laden -> danach fragt
      # er den Rest der Session nicht mehr.
      "*".AddKeysToAgent = "yes";

      # github: immer diesen Key nehmen
      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = "yes";
      };
    };
  };

  # Persistenter OpenSSH-Agent als systemd-User-Service.
  # Socket: $XDG_RUNTIME_DIR/ssh-agent, SSH_AUTH_SOCK wird für die Shell gesetzt.
  services.ssh-agent.enable = true;

  # Lädt den Key beim Login automatisch in den Agent; die Passphrase kommt aus
  # dem gnome-keyring -> du musst nie mehr manuell entsperren. Ist (noch) keine
  # Passphrase im keyring hinterlegt, schlägt nur dieser Service still fehl und
  # du gibst sie wie gehabt beim ersten git-Befehl einmalig ein (AddKeysToAgent).
  #
  # EINMALIG nach dem ersten Rebuild ausführen (fragt dann nach der Passphrase):
  #   secret-tool store --label='ssh id_ed25519 passphrase' ssh id_ed25519
  systemd.user.services.ssh-add-key = {
    Unit = {
      Description = "SSH-Key mit Passphrase aus gnome-keyring in den Agent laden";
      After = [ "ssh-agent.service" "graphical-session.target" ];
      Requires = [ "ssh-agent.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      Environment = [
        "SSH_AUTH_SOCK=%t/ssh-agent"
        "SSH_ASKPASS=${keyringAskpass}"
        "SSH_ASKPASS_REQUIRE=force"
      ];
      ExecStart = "${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
