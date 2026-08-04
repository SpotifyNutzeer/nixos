{ pkgs, rodecaster-volume-bridge, ... }:
let
  bridge = pkgs.python3Packages.buildPythonApplication {
    pname = "rodecaster-volume-bridge";
    version = "0.1.0";
    src = rodecaster-volume-bridge;
    pyproject = true;
    build-system = with pkgs.python3Packages; [ setuptools wheel ];
    dependencies = with pkgs.python3Packages; [
      mido
      python-rtmidi
      websockets
      tomli-w
      dbus-fast
    ];
    # The suite needs MIDI hardware and a D-Bus session bus, neither of which
    # exists in the build sandbox.
    doCheck = false;
  };
in
{
  home.packages = [ bridge ];          # makes `rodecaster-volume-bridge --learn` available in the terminal

  systemd.user.services.rodecaster-volume-bridge = {
    Unit = {
      Description = "RodeCaster MIDI Volume Bridge";
      # Needs the session bus to talk MPRIS to Spotify, and pipewire-pulse for
      # the MIDI stack.
      After = [ "pipewire-pulse.service" "dbus.socket" ];
    };
    Service = {
      ExecStart = "${bridge}/bin/rodecaster-volume-bridge";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
