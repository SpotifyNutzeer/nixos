{ ... }:
{
  programs.ssh = {
    enable = true;
    # our own defaults instead of the (deprecated) home-manager presets
    enableDefaultConfig = false;

    settings = {
      # Load keys into the agent automatically on first use.
      "*".AddKeysToAgent = "yes";

      # github: always use this key
      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = "yes";
      };
    };
  };
}
