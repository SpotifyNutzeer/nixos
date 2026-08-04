{ pkgs, ... }:
let
  # Askpass helper: reads the key passphrase from the gnome-keyring.
  keyringAskpass = pkgs.writeShellScript "ssh-askpass-keyring" ''
    exec ${pkgs.libsecret}/bin/secret-tool lookup ssh id_ed25519
  '';
in
{
  # secret-tool for one-time storing/reading of the passphrase
  home.packages = [ pkgs.libsecret ];

  # Persistent OpenSSH agent as a systemd user service.
  services.ssh-agent.enable = true;

  # Automatically loads the key into the agent at login (passphrase from gnome-keyring).
  # Run ONCE after the first rebuild (prompts for the passphrase):
  #   secret-tool store --label='ssh id_ed25519 passphrase' ssh id_ed25519
  systemd.user.services.ssh-add-key = {
    Unit = {
      Description = "Load SSH key into the agent with passphrase from gnome-keyring";
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
