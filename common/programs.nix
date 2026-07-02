{ pkgs, inputs, tidaluna, gsr-ui-nix, ... }:
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
    hyfetch
    usbutils
    (prismlauncher.override {
      jdks = [
        zulu8
        zulu17
        zulu21
        zulu25
      ];
    })
    telegram-desktop
  ];

  programs.fish.enable                = true;
  programs.nano.enable                = false;
  # gpu-screen-recorder + ShadowPlay-artige Overlay-UI aus der gsr-ui-nix Flake.
  # Recorder-Paket aus der Flake (5.13.8, gleiche Version wie nixpkgs), damit
  # System und UI dieselbe Recorder-Binary nutzen. ui.enable legt zusaetzlich
  # den security.wrapper fuer gsr-global-hotkeys (cap_setuid+ep) und den
  # gpu-screen-recorder-ui systemd-User-Service an.
  programs.gpu-screen-recorder = {
    package   = gsr-ui-nix.packages.${pkgs.stdenv.hostPlatform.system}.gpu-screen-recorder;
    enable    = true;
    ui.enable = true;
  };
  programs.git = {
    enable = true;
    config.user = {
      name = "Paul Reitmayer";
      email = "paul.reitmayer@pm.me";
      signingKey = "~/.ssh/id_ed25519.pub";
    };
    config.gpg.format = "ssh";
    config.commit.gpgsign = "true";
  };
}
