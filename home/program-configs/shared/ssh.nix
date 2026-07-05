{ ... }:
{
  programs.ssh = {
    enable = true;
    # eigene Defaults statt der (deprecateten) home-manager-Vorgaben
    enableDefaultConfig = false;

    settings = {
      # Keys beim ersten Benutzen automatisch in den Agent laden.
      "*".AddKeysToAgent = "yes";

      # github: immer diesen Key nehmen
      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = "yes";
      };
    };
  };
}
