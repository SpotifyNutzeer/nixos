{ ... }:
{
  # macOS hat einen system-eigenen ssh-agent (kein systemd noetig). UseKeychain
  # laedt die Passphrase aus der macOS-Keychain; zusammen mit AddKeysToAgent (shared)
  # wird der Key einmalig entsperrt und danach nicht mehr abgefragt.
  programs.ssh.settings."*".UseKeychain = "yes";
}
