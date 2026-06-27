{ pkgs, ... }:
{
  systemd.user.services.fosi-keepalive = {
    Unit = {
      Description = "Fosi Audio ZH3 Hardware Gate Defeater";
      After = [ "pipewire-pulse.service" ];
      Requires = [ "pipewire-pulse.service" ];
    };
    Service = {
      Type = "simple";
      Environment = [ "PULSE_SINK=alsa_output.usb-Fosi_Fosi_Audio_ZH3-00.analog-stereo" ];
      ExecStart = "${pkgs.sox}/bin/play -q -n synth brownnoise vol 0.00001";
      Restart = "always";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
