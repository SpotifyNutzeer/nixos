{ pkgs, ... }:
{
  users.users."paul" = {
    isNormalUser = true;
    description = "Paul Reitmayer";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    shell = pkgs.fish;
    # SSH-Key vom Desktop: Login per Key auf allen Hosts, auch wenn (wie bei
    # einer frischen Installation) noch kein Passwort gesetzt ist.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICB4D3JVDFWLJGkVS+uD1I0KvYP1IGEC9idw66GfO9uO paul@paul-desktop"
    ];
  };
}
