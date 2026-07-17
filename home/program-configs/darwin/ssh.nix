{ ... }:
{
  # macOS hat einen system-eigenen ssh-agent (kein systemd noetig). UseKeychain
  # laedt die Passphrase aus der macOS-Keychain; zusammen mit AddKeysToAgent (shared)
  # wird der Key einmalig entsperrt und danach nicht mehr abgefragt.
  programs.ssh.settings."*" = {
    UseKeychain = "yes";
    # UseKeychain ist ein Apple-Patch; Upstream-OpenSSH aus Nix (z.B. im PATH
    # des claudeMemorySync-Activation-Scripts) bricht sonst mit "Bad
    # configuration option" ab. IgnoreUnknown laesst fremde ssh-Varianten die
    # Option ueberspringen. (Muss im Config-File VOR UseKeychain stehen —
    # passt, da home-manager Optionen alphabetisch rendert.)
    IgnoreUnknown = "UseKeychain";
  };
}
