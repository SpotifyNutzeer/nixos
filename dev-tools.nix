{ config, lib, pkgs, ... }:
let
  cfg = config.my.devtools;
in
{
  options.my.devtools = {
    enable = lib.mkEnableOption "meine Entwickler-Tool-Sammlung";
    
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Zusätzliche Pakete, die mit der Sammlung installiert werden.";
    };
  };
  
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ripgrep
      fd
      jq
    ] ++ cfg.extraPackages;
  };
}
