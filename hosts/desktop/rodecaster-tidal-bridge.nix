{ pkgs, rodecaster-tidal-bridge, ... }:
let
  bridge = pkgs.python3Packages.buildPythonApplication {
    pname = "rodecaster-tidal-bridge";
    version = "0.1.0";
    src = rodecaster-tidal-bridge;
    pyproject = true;
    build-system = with pkgs.python3Packages; [ setuptools wheel ];
    dependencies = with pkgs.python3Packages; [
      mido
      python-rtmidi
      websockets
      tomli-w
    ];
    doCheck = false;   # tests need MIDI hardware / pytest-asyncio
  };
in
{
  home.packages = [ bridge ];          # makes `rodecaster-tidal-bridge --learn` available in the terminal

  systemd.user.services.rodecaster-tidal-bridge = {
    Unit = {
      Description = "RodeCaster → Tidal MIDI Bridge";
      After = [ "pipewire-pulse.service" ];
    };
    Service = {
      ExecStart = "${bridge}/bin/rodecaster-tidal-bridge";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
