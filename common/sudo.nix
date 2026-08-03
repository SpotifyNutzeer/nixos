{ pkgs, ... }:
let
  # GUI-Passwortabfrage fuer sudo, wenn kein Terminal da ist — z.B. in
  # Claude-Code-Sessions (deren Bash-Tool laeuft ohne TTY). sudo faellt ohne
  # TTY automatisch auf den in /etc/sudo.conf registrierten Askpass-Helper
  # zurueck; in interaktiven Shells erzwingt `sudo -A` den Dialog. $1 ist
  # der sudo-Prompt ("[sudo] password for paul:"). Darwin-Gegenstueck:
  # hosts/macbook/sudo-askpass.nix.
  askpass = pkgs.writeShellScript "sudo-askpass" ''
    exec ${pkgs.zenity}/bin/zenity --entry --hide-text --title sudo --text "''${1:-Passwort fuer sudo:}"
  '';
in
{
  security.sudo.extraConfig = ''
    Defaults pwfeedback
    '';

  environment.etc."sudo.conf".text = "Path askpass ${askpass}\n";
}
