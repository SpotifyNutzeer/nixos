{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tidaluna.url = "github:Inrixia/TidaLuna";
    nixcord.url = "github:FlameFlag/nixcord";
    catppuccin.url = "github:catppuccin/nix";
    home-manager = {
      url = "github:nix-community/home-manager";
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
  };

  outputs = { self, nixpkgs, home-manager, dotfiles, rodecaster-tidal-bridge, tidaluna, nixcord, catppuccin, ... }:
  let
    mkHost = host: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit tidaluna; };
      modules = [
        ./hosts/${host}
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit dotfiles rodecaster-tidal-bridge nixcord catppuccin; };
          home-manager.users.paul = import ./home/home.nix;
          nixpkgs.overlays = [ tidaluna.overlays.default ];
        }
      ];
    };
  in {
    nixosConfigurations = {
      vm      = mkHost "vm";
      desktop = mkHost "desktop";
    };
  };
}
