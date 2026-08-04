{ pkgs, ... }:
let
  # GUI password prompt for sudo when no terminal is available - e.g. in
  # Claude Code sessions (their Bash tool runs without a TTY). Without a TTY,
  # sudo automatically falls back to the askpass helper registered in
  # /etc/sudo.conf; in interactive shells `sudo -A` forces the dialog. $1 is
  # the sudo prompt ("[sudo] password for paul:"). Darwin counterpart:
  # hosts/macbook/sudo-askpass.nix.
  askpass = pkgs.writeShellScript "sudo-askpass" ''
    exec ${pkgs.zenity}/bin/zenity --entry --hide-text --title sudo --text "''${1:-sudo password:}"
  '';
in
{
  security.sudo.extraConfig = ''
    Defaults pwfeedback
    '';

  environment.etc."sudo.conf".text = "Path askpass ${askpass}\n";
}
