{ pkgs, inputs, tidaluna, ... }:
let
  # tidal-hifi (TidaLuna) gewrappt: pinnt Electrons safeStorage auf gnome-libsecret.
  # Sonst waehlt 'auto' unter Hyprland inkonsistent ein Backend, der
  # luna-trust-store.enc wird nicht entschluesselt und TidaLuna fragt bei JEDEM
  # Start neu nach Plugin-Permissions. Braucht entsperrten gnome-keyring
  # (siehe hosts/desktop/sddm.nix).
  tidal-hifi = pkgs.symlinkJoin {
    name = "tidal-hifi-gnome-libsecret";
    paths = [ tidaluna.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/tidal-hifi --add-flags "--password-store=gnome-libsecret"
    '';
  };
in
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vim
    htop
    tmux
    kitty
    alacritty
    claude-code
    tidal-hifi
    pavucontrol
    grimblast
    fastfetch
    (prismlauncher.override {
      jdks = [
        zulu8
        zulu17
        zulu21
        zulu25
      ];
    })
  ];

  programs.fish.enable = true;
  programs.nano.enable = false;
  programs.git = {
    enable = true;
    config.user.name = "Paul Reitmayer";
    config.user.email = "paul.reitmayer@pm.me";
  };
}
