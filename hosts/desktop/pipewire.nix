{ dotfiles, ... }:
{
  xdg.configFile."pipewire/pipewire.conf.d".source =
    "${dotfiles}/.config/pipewire/pipewire.conf.d";

  # Pin Tidal Hi-Fi routing to the virtual sink "sink_music_combined"
  # (defined in dotfiles, 99-rodecaster-multichannel.conf). The sink used to be
  # called "sink_tidal_combined"; it was renamed player-neutral in dotfiles and
  # keeps that name here.
  #
  # Tidal (Electron/Chromium) registers as a pipewire-pulse client with
  # application.name = "Chromium" and WITHOUT an application.id. WirePlumber
  # builds its restore key from the first present one of application.id /
  # application.name / media.name / node.name (state-stream.lua:formKey) —
  # i.e. "Output/Audio:application.name:Chromium". That is exactly the same key
  # as for the regular Chromium browser: the two overwrite each other, which is
  # why the sink set in pavucontrol gets lost after every restart.
  #
  # update-props sets target.object as a REAL node property (only pulse.rules
  # can do that for client streams; stream.rules only changes a local copy in
  # the restore hook). WirePlumber linking prefers this property, and the
  # restore no longer overwrites it (state-stream.lua, fix #335).
  xdg.configFile."pipewire/pipewire-pulse.conf.d/50-tidal-target.conf".text = ''
    pulse.rules = [
      {
        matches = [ { application.process.binary = "tidal-hifi" } ]
        actions = { update-props = { target.object = "sink_music_combined" } }
      }
    ]
  '';
}
