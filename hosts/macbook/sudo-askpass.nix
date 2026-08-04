{ pkgs, ... }:
let
  # GUI password prompt for sudo when no terminal is present — e.g. in
  # Claude Code sessions (their Bash tool runs without a TTY). Without a
  # TTY, sudo automatically falls back to the askpass helper registered in
  # /etc/sudo.conf; interactively, `sudo -A` forces the dialog. $1 is the
  # sudo prompt. NixOS counterpart (zenity): common/sudo.nix.
  # Deliberately plain `display dialog` without "tell System Events" — that
  # way no TCC automation approval is needed for the calling terminal.
  askpass = pkgs.writeShellScript "sudo-askpass" ''
    exec /usr/bin/osascript -e 'on run argv
      set dialogPrompt to "sudo password:"
      if (count of argv) > 0 then set dialogPrompt to item 1 of argv
      display dialog dialogPrompt with title "sudo" with icon caution default answer "" with hidden answer
      return text returned of result
    end run' "$@"
  '';
in
{
  # nix-darwin creates /etc/sudo.conf as a symlink into /etc/static; sudo
  # accepts that (the target file in the store is owned by root, not
  # world-writable).
  environment.etc."sudo.conf".text = "Path askpass ${askpass}\n";
}
