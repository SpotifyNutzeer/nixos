{ pkgs, ... }:
let
  # GUI-Passwortabfrage fuer sudo, wenn kein Terminal da ist — z.B. in
  # Claude-Code-Sessions (deren Bash-Tool laeuft ohne TTY). sudo faellt ohne
  # TTY automatisch auf den in /etc/sudo.conf registrierten Askpass-Helper
  # zurueck; interaktiv erzwingt `sudo -A` den Dialog. $1 ist der
  # sudo-Prompt. NixOS-Gegenstueck (zenity): common/sudo.nix.
  # Bewusst plain `display dialog` ohne "tell System Events" — das braucht
  # keine TCC-Automation-Freigabe fuer das aufrufende Terminal.
  askpass = pkgs.writeShellScript "sudo-askpass" ''
    exec /usr/bin/osascript -e 'on run argv
      set dialogPrompt to "Passwort fuer sudo:"
      if (count of argv) > 0 then set dialogPrompt to item 1 of argv
      display dialog dialogPrompt with title "sudo" with icon caution default answer "" with hidden answer
      return text returned of result
    end run' "$@"
  '';
in
{
  # nix-darwin legt /etc/sudo.conf als Symlink nach /etc/static an; sudo
  # akzeptiert das (Zieldatei im Store gehoert root, nicht world-writable).
  environment.etc."sudo.conf".text = "Path askpass ${askpass}\n";
}
