{ pkgs, ... }:
let
  # Askpass-Helfer: liest die Key-Passphrase aus dem gnome-keyring.
  keyringAskpass = pkgs.writeShellScript "ssh-askpass-keyring" ''
    exec ${pkgs.libsecret}/bin/secret-tool lookup ssh id_ed25519
  '';
in
{
  # secret-tool zum einmaligen Ablegen/Auslesen der Passphrase
  home.packages = [ pkgs.libsecret ];

  # Persistenter OpenSSH-Agent als systemd-User-Service.
  services.ssh-agent.enable = true;

  # Laedt den Key beim Login automatisch in den Agent (Passphrase aus gnome-keyring).
  # EINMALIG nach dem ersten Rebuild ausfuehren (fragt nach der Passphrase):
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
