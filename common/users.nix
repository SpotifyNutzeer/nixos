{ pkgs, ... }:
{
  users.users."paul" = {
    isNormalUser = true;
    description = "Paul Reitmayer";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
    # SSH key from the desktop: key-based login on all hosts, even when (as on
    # a fresh installation) no password has been set yet.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICB4D3JVDFWLJGkVS+uD1I0KvYP1IGEC9idw66GfO9uO paul@paul-desktop"
    ];
  };
}
