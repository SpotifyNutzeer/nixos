{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    gsr-ui-nix = {
      url = "github:rPlakama/gsr-ui-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tidaluna.url = "github:Inrixia/TidaLuna";
    nixcord.url = "github:FlameFlag/nixcord";
    catppuccin.url = "github:catppuccin/nix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dotfiles = {
      url = "github:SpotifyNutzeer/dotfiles";
      flake = false;
    };
    rodecaster-tidal-bridge = {
      url = "github:SpotifyNutzeer/rodecaster-tidal-bridge";
      flake = false;
    };
    streamcontroller-tidal = {
      url = "github:SpotifyNutzeer/streamcontroller-tidal";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, disko, dotfiles, rodecaster-tidal-bridge, streamcontroller-tidal, tidaluna, nixcord, catppuccin, gsr-ui-nix, ... }:
  let
    # Das Tidal-Plugin importiert `websockets`, das StreamController in nixpkgs
    # NICHT mitbringt (nur websocket-client). Da das Plugin-Backend direkt im
    # StreamController-Python-Prozess laeuft und `pip install` auf NixOS nicht
    # funktioniert, wird die Library hier ins Paket injiziert.
    streamcontrollerOverlay = final: prev: {
      streamcontroller = prev.streamcontroller.overrideAttrs (old: {
        buildInputs = old.buildInputs ++ [ final.python3Packages.websockets ];
      });
    };
    mkHost = host: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit tidaluna catppuccin streamcontroller-tidal gsr-ui-nix; };
      modules = [
        ./hosts/${host}
        disko.nixosModules.disko
        gsr-ui-nix.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit dotfiles rodecaster-tidal-bridge nixcord catppuccin; };
          home-manager.users.paul = import ./home/home-linux.nix;
          nixpkgs.overlays = [ tidaluna.overlays.default streamcontrollerOverlay ];
        }
      ];
    };
    mkDarwin = host: nix-darwin.lib.darwinSystem {
      specialArgs = { inherit catppuccin; };
      modules = [
        ./hosts/${host}
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit catppuccin; };
          home-manager.users.paulweber = import ./home/home-darwin.nix;
        }
      ];
    };
  in {
    nixosConfigurations = {
      vm      = mkHost "vm";
      desktop = mkHost "desktop";
      laptop  = mkHost "laptop";
    };

    darwinConfigurations = {
      macbook = mkDarwin "macbook";
    };
  };
}
