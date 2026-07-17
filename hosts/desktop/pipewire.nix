{ dotfiles, ... }:
{
  xdg.configFile."pipewire/pipewire.conf.d".source =
    "${dotfiles}/.config/pipewire/pipewire.conf.d";

  # Tidal Hi-Fi fest auf den virtuellen Sink "sink_tidal_combined" routen.
  #
  # Tidal (Electron/Chromium) meldet sich als pipewire-pulse-Client mit
  # application.name = "Chromium" und OHNE application.id. WirePlumber bildet
  # seinen Restore-Key aus der ersten vorhandenen von application.id /
  # application.name / media.name / node.name (state-stream.lua:formKey) —
  # also "Output/Audio:application.name:Chromium". Das ist exakt derselbe Key
  # wie beim normalen Chromium-Browser: beide ueberschreiben sich gegenseitig,
  # weshalb die in pavucontrol gesetzte Senke nach jedem Neustart verloren geht.
  #
  # update-props setzt target.object als ECHTE Node-Property (nur pulse.rules
  # kann das fuer Client-Streams; stream.rules aendert nur eine lokale Kopie im
  # Restore-Hook). WirePlumber-Linking bevorzugt diese Property, und der
  # Restore ueberschreibt sie nicht mehr (state-stream.lua, Fix #335).
  xdg.configFile."pipewire/pipewire-pulse.conf.d/50-tidal-target.conf".text = ''
    pulse.rules = [
      {
        matches = [ { application.process.binary = "tidal-hifi" } ]
        actions = { update-props = { target.object = "sink_tidal_combined" } }
      }
    ]
  '';
}
